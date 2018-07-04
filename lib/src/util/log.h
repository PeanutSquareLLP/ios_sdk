//
//  log.h
//  SparkLib
//
//  Created by volodymyr on 05/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "spark_api.h"
#import <Foundation/Foundation.h>

@protocol SparkLogListener <NSObject>
- (void)log_received:(NSString *)msg
    with_module:(NSString *)module with_level:(SparkLogLevel)level;
@end

@interface SparkLog : NSObject

+ (instancetype)log_with_module:(NSString*)module;
+ (void)set_verbose_level:(SparkLogLevel)level;

+ (void)register_listener:(id <SparkLogListener>)listener;
+ (void)unregister_listener:(id <SparkLogListener>)listener;

- (void)debug:(NSString *)msg, ...;
- (void)info:(NSString *)msg, ...;
- (void)warn:(NSString *)msg, ...;
- (void)err:(NSString *)msg, ...;
- (void)crit:(NSString *)msg, ...;

@end
