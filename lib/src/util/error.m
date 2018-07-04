//
//  error.m
//  SparkLib
//
//  Created by volodymyr on 21/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "error.h"

NSString *spark_domain = @"spark-sdk";

@implementation SparkError

+ (NSError *)code2error:(SparkErrorCode)code
{
    return [NSError errorWithDomain:spark_domain code:code userInfo:nil];
}

+ (NSError *)code2error:(SparkErrorCode)code with_desc:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSError *result = [SparkError code2error:code with_info:nil
        with_desc:format with_args:args];
    va_end(args);
    return result;
}

+ (NSError *)code2error:(SparkErrorCode)code with_info:(NSDictionary *)info
    with_desc:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSError *result = [SparkError code2error:code with_info:info
        with_desc:format with_args:args];
    va_end(args);
    return result;
}

+ (NSError *)code2error:(SparkErrorCode)code with_info:(NSDictionary *)info
    with_desc:(NSString *)format with_args:(va_list)args
{
    NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
    NSMutableDictionary<NSErrorUserInfoKey, id> *dict =
        [NSMutableDictionary dictionaryWithDictionary: @{@"details": s}];
    if (info)
        [dict setValue:info forKey:@"info"];
    return [NSError errorWithDomain:spark_domain code:code userInfo:dict];
}

@end
