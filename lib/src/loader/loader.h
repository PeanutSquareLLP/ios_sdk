//
//  loader.h
//  SparkLib
//
//  Created by volodymyr on 02/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "player_proxy.h"
#import "conf.h"
#import "stats.h"

// JS binding API: update spark_mobile_sdk_api mocha test once adding more
// APIs here
@interface SparkLoader : NSObject

- (instancetype)init:(NSString *)customer;
- (void)uninit;

- (BOOL)is_loaded;
- (NSString *)get_version;
- (NSNumber *)get_tag;

- (SparkConf *)get_conf:(NSString *)feature;
- (BOOL)is_feature_enabled:(NSString *)feature;
- (id<SparkStats>)get_stats:(NSString *)feature;

- (id<SparkLibJSDelegate>)add_player_proxy:(AVPlayerItem *)item
    player:(id<SparkLibPlayerDelegate>)player;
- (void)call_delegate_for_proxy:(NSString *)proxy_id
    method:(NSString *)method value:(id)value param:(id)param;
- (void)remove_player_proxy:(AVPlayerItem *)item;


@end
