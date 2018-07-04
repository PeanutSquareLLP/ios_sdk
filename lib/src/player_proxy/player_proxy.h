//
//  player_proxy.h
//  SparkLib
//
//  Created by alexeym on 23/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JSContext.h>
#import <JavaScriptCore/JSExport.h>
#import "spark_api.h"
#import <AVFoundation/AVFoundation.h>

@class SparkLoader;

@protocol SparkLibExports <JSExport>
@property(readonly) NSString* proxy_id;
- (NSString *)get_state;
- (NSString *)get_url;
- (NSNumber *)get_duration;
- (NSNumber *)get_pos;
- (NSNumber *)get_bitrate;
- (NSArray *)get_buffered;
- (NSDictionary *)get_levels;
- (NSNumber *)get_bandwidth;
- (NSDictionary *)get_segment_info:(NSString *)url;
- (BOOL)is_ad_playing;
- (void)wrapper_attached;
- (void)uninit;
- (void)log:(NSString *)msg;
- (NSDictionary *)settings:(NSDictionary *)opt;
- (NSString *)get_app_label;
- (void)thumbnails_init:(NSDictionary *)thumb_info;
@end

@interface SparkLibProxy: NSObject <SparkLibExports, SparkLibJSDelegate>
@property(readonly) BOOL ready;
- (instancetype)init_with_item:(AVPlayerItem *)item
    loader:(SparkLoader *)loader player:(id<SparkLibPlayerDelegate>)player;
- (void)set_ready;
@end
