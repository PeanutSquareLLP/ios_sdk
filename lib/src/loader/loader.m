//
//  loader.m
//  SparkLib
//
//  Created by volodymyr on 02/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "loader.h"
#import "window_timers.h"
#import "xmlhttprequest.h"
#import "log.h"
#import "error.h"
#import "stats.h"
#import "player_proxy.h"
#import "proxy_manager.h"
#import <JavaScriptCore/JSContext.h>

#define SERVER_DOMAIN @"https://player.h-cdn.com"
// XXX volodymyr: avoid shorted loader by specifying fake md5,
// fix properly by providing a query param to ignore shortifying loader.js
#define LOADER_URL_FMT SERVER_DOMAIN @"/loader.js?customer=%@&md5=00-11111111"
#define WEBVIEW_URL_FMT SERVER_DOMAIN @"/webview?customer=%@"
#define PROXY_KEY @"spark_ios_proxy"
#define PROXY_PATH_FMT @"window." PROXY_KEY @"['%@']"
#define PROXY_DELEGATE_PATH_FMT PROXY_PATH_FMT @".delegate"
#define PROXY_REMOVE_FMT @"delete " PROXY_PATH_FMT
#define BASIC_FMT @"window.spark_ios_sdk = {version:'%@'};window." PROXY_KEY @" = {};"
#define LOCATION_FMT @"_hola_location = '" WEBVIEW_URL_FMT @"'"
// XXX alexeym: replace with spark_web API
#define WRAPPER_UPDATE @"window.hola_cdn.api.ios_ready()"

// XXX volodymyr: we want to reduce customer integration to as little as
// possible, so javascript dependecies simulating DOM etc are integrated
// within the library code as base64 string. solve this properly by either:
// - (PREFERED) removing DOM dependency from loader.js or
// - loading the js assets from the backend and store permanently in the app
extern NSString * const __jsext_base64_autogen;
#import "jsext/autogen.m"

@interface SparkLoaderStatsProxy: NSObject<SparkStats>
- (instancetype)init:(SparkLoader *)loader module:(NSString *)mod;
- (void)close;
@end

@interface SparkLoader () <SparkLogListener>
@property Boolean inited;
@property (copy) NSString *customer;
@property JSContext *jsctx;
@property SparkLog *log;
@property NSError *server_err;
@property NSError *cache_err;
@property SparkPlayerProxyManager* proxy_manager;
@property NSMutableDictionary<NSString *, SparkLoaderStatsProxy *> *stats;
@end

@implementation SparkLoader

- (void)dealloc
{
    [_log debug:@"spark loader for %@ released", _customer];
    // release stats proxy
    [[_stats allValues] enumerateObjectsUsingBlock:
         ^(SparkLoaderStatsProxy *obj, NSUInteger idx, BOOL *stop)
    {
        [obj close];
    }];
}

- (instancetype)init:(NSString *)customer
{
    _inited = YES;
    _customer = customer;
    _log = [SparkLog log_with_module:@"loader"];
    _proxy_manager = [[SparkPlayerProxyManager alloc] init];
    _stats = [[NSMutableDictionary alloc] init];
    [self _setup_js_env];
    [self _load_spark_js];
    return self;
}

- (void)uninit
{
    [SparkLog unregister_listener:self];
    [_proxy_manager uninit];
    _inited = NO;
}

- (void)_setup_js_env
{
    __weak typeof(self) _self = self;
    _jsctx = [JSContext new];
    _jsctx.exceptionHandler = ^(JSContext *context, JSValue *exception){
        [_self.log err:@"js exception from spark loader: %@", exception]; };
    [[XMLHttpRequest new] extend:_jsctx];
    [[WTWindowTimers new] extend:_jsctx];
    [_jsctx evaluateScript:[NSString stringWithFormat:LOCATION_FMT, _customer]
        withSourceURL:[NSURL URLWithString:@"location.js"]];
    [_jsctx evaluateScript:[[NSString alloc] initWithData:[[NSData alloc]
        initWithBase64EncodedString:__jsext_base64_autogen options:0]
        encoding:NSUTF8StringEncoding]
        withSourceURL:[NSURL URLWithString:@"dom.js"]];
    NSBundle* bundle = [NSBundle bundleForClass:NSClassFromString(@"SparkLoader")];
    NSString* version = bundle.infoDictionary[@"CFBundleShortVersionString"];
    NSString* basic = [NSString stringWithFormat:BASIC_FMT, version];
    [_jsctx evaluateScript:basic withSourceURL:[NSURL URLWithString:@"basic.js"]];
}

- (void)_load_spark_js
{
    NSURL *loader_url = [NSURL URLWithString:
        [NSString stringWithFormat:LOADER_URL_FMT, _customer]];
    NSString *loader_path = [self _get_loader_path];
    dispatch_queue_t backgroundQueue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(backgroundQueue, ^{
        if (!_inited)
            return;
        // use cached version immediately
        NSError *cache_err, *load_err;
        NSString *loader_js = [NSString stringWithContentsOfFile:loader_path
            encoding:NSUTF8StringEncoding error:&cache_err];
        if (cache_err)
            [self _spark_js_failed:cache_err cached:YES];
        else
        {
            [_jsctx evaluateScript:loader_js withSourceURL:loader_url];
            [self _spark_js_loaded:YES];
        }
        // and update cache with latest version from the server for next start
        loader_js = [NSString stringWithContentsOfURL:loader_url
            encoding:NSUTF8StringEncoding error:&load_err];
        if (load_err)
            return [self _spark_js_failed:load_err cached:NO];
        if ([self is_loaded])
            [_log info:@"updating cached loader with latest version"];
        else
        {
            [_jsctx evaluateScript:loader_js withSourceURL:loader_url];
            [self _spark_js_loaded:NO];
        }
        [loader_js writeToFile:loader_path atomically:YES
            encoding:NSUTF8StringEncoding error:&load_err];
        if (load_err)
            [_log err:@"failed to save spark loader at %@", loader_path];
    });
}

- (void)_spark_js_loaded:(BOOL)from_cache
{
    if (![self is_loaded])
    {
        NSError *err = [SparkError code2error:spark_err_loader_js_init
            with_desc:@"failed to parse loader js"];
        return [self _spark_js_failed:err cached:from_cache];
    }
    [_log info:@"spark loader v%@ tag %@ loaded for %@ %@",
        [self get_version], [self get_tag], _customer,
        from_cache ? @"(from cache)" : @"(latest version)"];
    // from now on forward all logs from ios sdk to loader.js log
    [SparkLog register_listener:self];
}

- (void)_spark_js_failed:(NSError *)error cached:(BOOL)cached
{
    if (cached)
    {
        _cache_err = error;
        [_log info:@"no spark loader found in cache, "
             @"waiting for version from the server"];
    }
    else
    {
        _server_err = error;
        [_log err:@"no spark loader received from the server"];
    }
    if (_server_err && _cache_err)
    {
        [_log crit:@"missing spark loader: " \
            @"failed to load from both cache and server\n" \
            @"cache error: %@\nserver error: %@", _cache_err, _server_err];
    }
}

- (NSString *)_get_loader_path
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    // XXX volodymyr: avoid stacking up multiple loader files (e.g. in demo app
    // where you can switch between the customers)
    return [dir stringByAppendingPathComponent:
        [NSString stringWithFormat:@"spark_loader_%@.js", _customer]];
}

- (JSValue *)_jsexec:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [_jsctx evaluateScript:s];
}

- (void)log_received:(NSString *)msg
    with_module:(NSString *)module with_level:(SparkLogLevel)level
{
    static NSString * const level2method[] = {
        [SparkLogLevelDebug] = @"debug",
        [SparkLogLevelInfo] = @"info",
        [SparkLogLevelWarning] = @"warn",
        [SparkLogLevelError] = @"err",
        [SparkLogLevelCritical] = @"crit",
    };
    msg = [msg stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    [self _jsexec:@"window.hola_cdn.log.set_type('ios_sdk')"
        @".set_module('%@').%@('%@')", module, level2method[level], msg];
}

- (BOOL)is_loaded {
    return ![self _jsexec:@"window.hola_cdn"].isUndefined;
}

- (NSString *)get_version
{
    JSValue *val = [self _jsexec:@"window.hola_cdn.ver"];
    return val.isString && !val.isUndefined ? [val toString] : nil;
}

- (NSNumber *)get_tag
{
    JSValue *val = [self _jsexec:@"window.hola_cdn.tag.id"];
    return val.isNumber ? [val toNumber] : nil;
}

- (SparkConf *)get_conf:(NSString *)feature;
{
    BOOL is_root = [feature isEqualToString:@"spark"];
    if (!is_root && ![self is_feature_enabled:feature])
        return nil;
    JSValue *val = [self _jsexec:[NSString stringWithFormat:
        @"window.hola_cdn.api.get_spark().%@", is_root ? @"conf" :
        [NSString stringWithFormat: @"features.%@.module.conf", feature]]];
    return [[SparkConf alloc] init:[val toDictionary]];
}

- (BOOL)is_feature_enabled:(NSString *)feature
{
    JSValue *val = [self _jsexec:
        @"window.hola_cdn.api.get_spark().is_feature_enabled('%@')", feature];
    return [val toBool];
}

- (id<SparkStats>)get_stats:(NSString *)feature
{
    if (!_stats[feature])
    {
        _stats[feature] = [[SparkLoaderStatsProxy alloc] init:self
            module:feature];
    }
    return _stats[feature];
}

- (id<SparkLibJSDelegate>)add_player_proxy:(AVPlayerItem *)item
    player:(id<SparkLibPlayerDelegate>)player
{
    SparkLibProxy *proxy = [_proxy_manager add_player_proxy:item
        loader:self player:player];
    if (proxy.ready)
    {
        [_log debug:@"proxy already exist for this item"];
        return proxy;
    }
    [proxy set_ready];
    [_log debug:@"new proxy added with id: %@", [proxy proxy_id]];
    [_jsctx[PROXY_KEY] setObject:proxy forKeyedSubscript:[proxy proxy_id]];
    [self _jsexec:WRAPPER_UPDATE];
    return proxy;
}

- (void)remove_player_proxy:(AVPlayerItem *)item
{
    SparkLibProxy *proxy = [_proxy_manager get_player_proxy:item];
    if (!proxy)
    {
        [_log debug:@"No proxy exist for this item"];
        return;
    }
    [_log debug:@"Removing proxy with id: %@", [proxy proxy_id]];
    [_jsctx[PROXY_KEY] setObject:nil forKeyedSubscript:[proxy proxy_id]];
    [self _jsexec:PROXY_REMOVE_FMT, [proxy proxy_id]];
    [_proxy_manager remove_player_proxy:item];
}

- (void)call_delegate_for_proxy:(NSString *)proxy_id method:(NSString *)method
    value:(id)value param:(id)param
{
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:2];
    if (value!=nil)
    {
        [args addObject:value];
        if (param!=nil)
            [args addObject:param];
    }
    [_log info:@"calling js delegate for %@", method];
    JSValue *delegate = [self _jsexec:PROXY_DELEGATE_PATH_FMT, proxy_id];
    if (!delegate.isUndefined && [delegate hasProperty:method])
        [delegate invokeMethod:method withArguments:args];
}

@end

@interface SparkLoaderStatsProxy ()
@property JSValue *stats_module;
@end

@implementation SparkLoaderStatsProxy
- (instancetype)init:(SparkLoader *)loader module:(NSString *)mod
{
    _stats_module = [loader _jsexec:
        @"window.hola_cdn.api.get_spark().modules.%@.module.stats", mod];
    if (_stats_module.isUndefined)
        _stats_module = nil;
    return self;
}

- (JSValue *)_invoke:(NSString *)method args:(NSArray *)args
{
    if (!_stats_module)
        return nil;
    return [_stats_module invokeMethod:method withArguments:args];
}

- (NSNumber *)get:(NSString *)name
{
    JSValue *val = [self _invoke:@"get" args:@[name]];
    return val && val.isNumber ? val.toNumber : nil;
}

- (void)set:(NSString *)name to:(NSNumber *)value
{
    [self _invoke:@"set" args:@[name, value]];
}

- (void)inc:(NSString *)name
{
    [self inc:name by:[NSNumber numberWithInt:1]];
}

- (void)inc:(NSString *)name by:(NSNumber *)increment
{
    [self _invoke:@"inc" args:@[name, increment]];
}

- (void)close
{
    _stats_module = nil;
}

@end
