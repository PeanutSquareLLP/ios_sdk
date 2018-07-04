//
//  thumbnails_config.h
//  SparkLib
//
//  Created by alexeym on 05/04/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThumbnailsConfig : NSObject
@property NSArray<NSString *> *cdns;
@property NSArray<NSString *> *urls;
@property NSNumber *width;
@property NSNumber *height;
@property NSNumber *group_size;
@property NSNumber *interval;
-(instancetype)init:(NSDictionary *)thumb_info;
@end
