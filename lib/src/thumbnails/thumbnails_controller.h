//
//  thumbnails_controller.h
//  SparkLib
//
//  Created by norlin on 28/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "spark_api_interface.h"
#import "thumbnails_config.h"

@interface ThumbnailsController : NSObject <SparkModule,
    SparkThumbnailsHandlerDelegate>
@property ThumbnailsConfig *config;
- (instancetype)init_with_player:(id<SparkLibPlayerDelegate>)player;
- (void)startWithInfo:(NSDictionary *)thumb_info;
- (void)get_state;
- (void)set_state;
- (void)seekStart:(CMTime)pos;
- (void)seekMove:(CMTime)pos;
- (void)seekEnd;
@end
