//
//  conf.m
//  SparkLib
//
//  Created by volodymyr on 03/04/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "conf.h"

#import <JavaScriptCore/JavaScriptCore.h>

@interface SparkConf ()
@property NSDictionary *dict;
@end

@implementation SparkConf

- (instancetype)init:(NSDictionary *)source
{
    _dict = source;
    return self;
}

- (instancetype)get_subconf:(NSString *)path;
{
    NSDictionary *subdict;
    if (!_dict || !(subdict = [_dict valueForKeyPath:path]))
        return nil;
    return [[SparkConf alloc] init:subdict];
}

- (id)get_raw:(NSString *)path
{
    return [self get_raw:path with_default:nil];
}

- (id)get_raw:(NSString *)path with_default:(id)def
{
    if (!_dict)
        return nil;
    return [_dict valueForKeyPath:path] ?: def;
}

- (NSString *)get_str:(NSString *)path
{
    return [self get_str:path with_default:nil];
}

- (NSString *)get_str:(NSString *)path with_default:(NSString *)def
{
    NSString *val = [self get_raw:path];
    return val ? : def;
}

- (NSNumber *)get_number:(NSString *)path
{
    return [self get_number:path with_default:nil];
}

- (NSNumber *)get_number:(NSString *)path with_default:(NSNumber *)def
{
    NSString *val = [self get_str:path];
    if (!val)
        return def;
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    return [f numberFromString:val];
}

- (BOOL)get_bool:(NSString *)path
{
    return [self get_bool:path with_default:NO];
}

- (BOOL)get_bool:(NSString *)path with_default:(BOOL)def
{
    return [self get_raw:path] ? YES : NO;
}

@end
