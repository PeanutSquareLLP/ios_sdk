//
//  log.m
//  SparkLib
//
//  Created by volodymyr on 05/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "log.h"

static SparkLogLevel __verbose_level = SparkLogLevelDebug;
static NSMutableArray<SparkLogListener> *__external_listeners = nil;

@interface SparkLog ()
@property (copy) NSString *module;
@end

@implementation SparkLog

+ (instancetype)log_with_module:(NSString*)module
{
    SparkLog *log = [SparkLog alloc];
    log.module = module;
    return log;
}

+ (void)set_verbose_level:(SparkLogLevel)level
{
    __verbose_level = level;
}

+ (void)register_listener:(id <SparkLogListener>)listener
{
    if (!__external_listeners)
    {
        __external_listeners = [NSMutableArray<SparkLogListener>
            arrayWithObjects:listener, nil];
    }
    else
        [__external_listeners addObject:listener];
}

+ (void)unregister_listener:(id <SparkLogListener>)listener
{
    if (__external_listeners)
        [__external_listeners removeObject:listener];
}

- (void)_log:(SparkLogLevel)level msg:(NSString *)fmt params:(va_list)params
{
    static NSString * const level2str[] = {
        [SparkLogLevelDebug] = @"DEBUG",
        [SparkLogLevelInfo] = @"INFO",
        [SparkLogLevelWarning] = @"WARN",
        [SparkLogLevelError] = @"ERR",
        [SparkLogLevelCritical] = @"CRIT",
    };
    NSString *msg = [[NSString alloc]initWithFormat:fmt arguments:params];
    if (level>=__verbose_level)
        NSLog(@"[Spark/%@] %@", level2str[level], msg);
    [__external_listeners enumerateObjectsUsingBlock:
        ^(id<SparkLogListener> listener, NSUInteger idx, BOOL *stop)
    {
         [listener log_received:msg with_module:_module with_level:level];
    }];
}

#define VA_LOG_IMPL(level, format) \
    va_list args; \
    va_start(args, format); \
    [self _log:level msg:format params:args]; \
    va_end(args)

- (void)debug:(NSString *)msg, ... {
    VA_LOG_IMPL(SparkLogLevelDebug, msg); }
- (void)info:(NSString *)msg, ... {
    VA_LOG_IMPL(SparkLogLevelInfo, msg); }
- (void)warn:(NSString *)msg, ... {
    VA_LOG_IMPL(SparkLogLevelWarning, msg); }
- (void)err:(NSString *)msg, ... {
    VA_LOG_IMPL(SparkLogLevelError, msg); }
- (void)crit:(NSString *)msg, ... {
    VA_LOG_IMPL(SparkLogLevelCritical, msg); }

@end
