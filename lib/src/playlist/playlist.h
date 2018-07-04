//
//  playlist.h
//  SparkLib
//
//  Created by volodymyr on 09/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "spark_api.h"
#import <Foundation/Foundation.h>

@interface SparkPlaylist : NSObject

+ (NSURLSessionDataTask *)getVideos:(NSString *)customer
    hits:(NSUInteger)hits over_last:(NSArray<NSString *> *)periods
    ondone:(void (^)(
        NSDictionary<NSString *, NSArray<SparkVideoItem *> *> *result,
        NSError *err))ondone;

@end
