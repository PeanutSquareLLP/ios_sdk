//
//  spark_api_interface.h
//  SparkLib
//
//  Created by alexeym on 28/03/2018.
//  Copyright © 2018 WebSpark. All rights reserved.
//

#ifndef spark_api_interface_h
#define spark_api_interface_h

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JSExport.h>
#import <CoreMedia/CoreMedia.h>

@protocol SparkModule <JSExport>
- (void)startWithInfo:(NSDictionary *)info;
- (void)get_state;
- (void)set_state;
@end

// Protocol for communicating with Thumbnails feature
@protocol SparkThumbnailsHandlerDelegate
- (void)seekStart:(CMTime)pos;
- (void)seekMove:(CMTime)pos;
- (void)seekEnd;
@end

// XXX volodymyr: ExternalWorld<>SparkLibAPI must be camelCase
@protocol SparkThumbnailsDelegate
- (UIView *)get_thumbnail_container;
- (void)setWidth:(NSNumber *)width andHeight:(NSNumber *)height;
- (void)display;
- (void)setPosition:(NSNumber *)position;
- (void)hide;
@end

// Protocol for communicating with SparkPlayer
// XXX volodymyr: ExternalWorld<>SparkLibAPI must be camelCase
@protocol SparkLibPlayerDelegate
- (BOOL)is_paused;
- (BOOL)is_ended;
- (BOOL)is_ad_playing;
- (BOOL)is_live;
@optional
- (NSURL *)get_origin_url:(NSURL *)url;
- (id<SparkThumbnailsDelegate>)get_thumbnails_delegate:(id<SparkThumbnailsHandlerDelegate>)handler;
@end

#endif /* spark_api_interface_h */
