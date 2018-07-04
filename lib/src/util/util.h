//
//  util.h
//  spark-ios-sdk
//
//  Created by volodymyr on 20/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SparkUtil : NSObject

+ (void)add_base_http_headers:(NSMutableURLRequest *)request;

+ (NSURL *)gen_unique_tmp_file:(NSString *)name with_ext:(NSString *)ext;

+ (NSURL *)get_spark_cmd_url:(NSString *)cmd
    with_customer:(NSString *)customer
    with_query:(NSArray<NSURLQueryItem *> *)items;

+ (NSURL *)get_fixed_url:(NSURL *)url;
+ (NSURL *)get_fixed_url_using_str:(NSString *)str;

+ (NSString *)data2str:(NSData *)data limit_to:(NSUInteger)max_len;

@end
