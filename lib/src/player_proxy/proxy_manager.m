//
//  proxy_manager.m
//  SparkLib
//
//  Created by alexeym on 26/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "proxy_manager.h"
#import "loader.h"
#import "log.h"

@interface SparkPlayerProxyManager ()
@property SparkLog *log;
@end

@implementation SparkPlayerProxyManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _proxy_list = [[NSMutableDictionary alloc] init];
        _log = [SparkLog log_with_module:@"proxy_manager"];
    }
    return self;
}

- (NSValue *)get_key:(AVPlayerItem *)item
{
    return [NSValue valueWithNonretainedObject:item];
}

- (SparkLibProxy *)add_player_proxy:(AVPlayerItem *)item
    loader:(SparkLoader *)loader player:(id<SparkLibPlayerDelegate>)player
{
    SparkLibProxy *proxy = [self get_player_proxy:item];
    if (proxy)
        return proxy;
    proxy = [[SparkLibProxy alloc] init_with_item:item loader:loader
        player:player];
    NSValue *key = [self get_key:item];
    [_proxy_list setObject:proxy forKey:key];
    return proxy;
}

- (void)remove_player_proxy:(AVPlayerItem *)item
{
    NSValue *key = [self get_key:item];
    SparkLibProxy *proxy = [self get_player_proxy_for_key:key];
    if (!proxy)
        return;
    [proxy uninit];
    [_proxy_list removeObjectForKey:key];
}

- (SparkLibProxy *)get_player_proxy:(AVPlayerItem *)item
{
    NSValue *key = [self get_key:item];
    return [_proxy_list objectForKey:key];
}

- (SparkLibProxy *)get_player_proxy_for_key:(NSValue *)key
{
    return [_proxy_list objectForKey:key];
}

- (void)uninit
{
    for (AVPlayerItem *item in _proxy_list)
    {
        SparkLibProxy *proxy = [self get_player_proxy:item];
        [proxy uninit];
    }
    [_proxy_list removeAllObjects];
}
@end
