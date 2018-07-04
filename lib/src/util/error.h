//
//  error.h
//  SparkLib
//
//  Created by volodymyr on 21/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    spark_err_notif_no_auth = 100,
    spark_err_preview_map_failed = 200,
    spark_err_preview_load_failed,
    spark_err_preview_attach_failed,
    spark_err_loader_js_init = 300,
    spark_err_playlist_api_failed = 400,
} SparkErrorCode;

@interface SparkError : NSObject

+ (NSError *)code2error:(SparkErrorCode)code;
+ (NSError *)code2error:(SparkErrorCode)code with_desc:(NSString *)format, ...;
+ (NSError *)code2error:(SparkErrorCode)code with_info:(NSDictionary *)info
    with_desc:(NSString *)format, ...;
+ (NSError *)code2error:(SparkErrorCode)code with_info:(NSDictionary *)info
    with_desc:(NSString *)format with_args:(va_list)args;


@end
