//
//  util.m
//  spark-ios-sdk
//
//  Created by volodymyr on 20/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "util.h"

@implementation SparkUtil

+ (void)add_base_http_headers:(NSMutableURLRequest *)request
{
    // XXX volodymyr: checkout if we really need referrer field, some of
    // zagent api do not work without it
    // XXX volodymyr: fix referrer to holaspark.com after ccgi-b released with
    // updated default whitelist
    [request setValue:@"https://holacdn.com/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"HolaSpark iOS SDK" forHTTPHeaderField:@"UserAgent"];
}

+ (NSURL *)gen_unique_tmp_file:(NSString *)name with_ext:(NSString *)ext
{
    NSString *uuid = [[NSUUID new] UUIDString];
    return [[NSURL fileURLWithPath:NSTemporaryDirectory()]
        URLByAppendingPathComponent:
        [NSString stringWithFormat: @"%@_%@.%@", name, uuid, ext]];
}

+ (NSURL *)get_spark_cmd_url:(NSString *)cmd
    with_customer:(NSString *)customer
    with_query:(NSArray<NSURLQueryItem *> *)query
{
    NSURLComponents *cmp = [NSURLComponents componentsWithString: [NSString
        stringWithFormat:@"https://holaspark-demo.h-cdn.com/api/%@", cmd]];
    cmp.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"customer" value:customer]];
    if (query)
        cmp.queryItems = [cmp.queryItems arrayByAddingObjectsFromArray:query];
    return cmp.URL;
}

+ (NSURL *)get_fixed_url:(NSURL *)url
{
    return [SparkUtil get_fixed_url_using_str:url.absoluteString];
}

+ (NSURL *)get_fixed_url_using_str:(NSString *)str
{
    if ([str hasPrefix:@"//"])
        str = [@"https:" stringByAppendingString:str];
    return [NSURL URLWithString:str];
}

+ (NSString *)data2str:(NSData *)data limit_to:(NSUInteger)max_len
{
    NSString *str = [[NSString alloc] initWithData:data
        encoding:NSASCIIStringEncoding];
    if (str.length>max_len)
        str = [str substringToIndex:max_len];
    return str;
}

@end
