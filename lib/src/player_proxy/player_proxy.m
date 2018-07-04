//
//  player_proxy.m
//  SparkLib
//
//  Created by alexeym on 23/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "player_proxy.h"
#import "log.h"
#import "loader.h"
#import "error.h"
#import "thumbnails_controller.h"

#define PLAYER_NAME @"SparkPlayer"

@interface SparkLibProxy()
@property(weak) AVPlayerItem *item;
@property(weak) id<SparkLibPlayerDelegate> player;
@property ThumbnailsController *thumb;
@end

@implementation SparkLibProxy

@synthesize proxy_id = _proxy_id;
@synthesize loader = _loader;

- (instancetype)init_with_item:(AVPlayerItem *)item
    loader:(SparkLoader *)loader
    player:(id<SparkLibPlayerDelegate>)player
{
    self = [super init];
    if (self) {
        _item = item;
        _proxy_id = [[NSUUID new] UUIDString];
        _player = player;
        _loader = loader;
        if (player != nil) {
            _thumb = [[ThumbnailsController alloc] init_with_player:player];
        } else {
            _thumb = nil;
        }
    }
    return self;
}

- (void)set_ready
{
    _ready = YES;
}

- (NSString *)get_state
{
    return [_player is_ended] ? @"IDLE" : [_player is_paused] ? @"PAUSED" :
        @"PLAYING";
}

- (NSString *)get_url
{
    AVURLAsset *asset = (AVURLAsset *)_item.asset;
    NSURL *url = [asset URL];
    if (url == nil){
        return @"";
    }
    return [[_player get_origin_url:url] absoluteString];
}

- (NSNumber *)get_duration
{
    return [NSNumber numberWithDouble:CMTimeGetSeconds(_item.duration)];
}

- (NSNumber *)get_pos
{
    return [NSNumber numberWithDouble:CMTimeGetSeconds(_item.currentTime)];
}

// XXX alexeym: not implemented
- (NSNumber *)get_bitrate
{
    return 0;
}

// XXX alexeym: not implemented
- (NSArray *)get_buffered
{
    return @[];
}

// XXX alexeym: not implemented
- (NSDictionary *)get_levels
{
    return @{};
}

// XXX alexeym: not implemented
- (NSNumber *)get_bandwidth
{
    return 0;
}

// XXX alexeym: not implemented
- (NSDictionary *)get_segment_info:(NSString *)url
{
    return @{};
}

- (void)wrapper_attached
{
}

- (void)uninit
{
    _thumb = nil;
}

- (void)log:(NSString *)msg
{
}

- (NSString*)get_player_ids
{
    return @"";
}

// XXX alexeym: not implemented
- (NSDictionary *)settings:(NSDictionary *)opt
{
    return @{};
}

- (NSString *)get_app_label
{
    return @"SparkLib";
}

// XXX alexeym: not implemented
- (NSNumber *)get_ws_socket
{
    return [NSNumber numberWithInt:-1];
}

- (void)seek:(NSNumber*)ms
{

}

- (BOOL)is_live_stream
{
    return [_player is_live];
}

- (void)js_attach_ready
{

}

- (BOOL)is_prepared
{
    return NO;
}

- (NSString *)get_player_name
{
    return PLAYER_NAME;
}

- (BOOL)is_ad_playing
{
    return [_player is_ad_playing];
}

- (void)call_delegate:(NSString *)method value:(id)value param:(id)param
{
    [_loader call_delegate_for_proxy:_proxy_id method:method
        value:value param:param];
}

- (void)call_delegate:(NSString *)method value:(id)value
{
    [self call_delegate:method value:value param:nil];
}

- (void)call_delegate:(NSString *)method
{
    [self call_delegate:method value:nil];
}

- (void)on_play
{
    [self call_delegate:@"on_play"];
}
- (void)on_pause
{
    [self call_delegate:@"on_pause"];
}
- (void)on_ad_suspend
{
    [self call_delegate:@"on_ad_suspend"];
}
- (void)on_ad_restore
{
    [self call_delegate:@"on_ad_restore"];
}
- (void)on_ended
{
    [self call_delegate:@"on_ended"];
}
- (void)on_timeupdate:(NSNumber*)pos
{
    [self call_delegate:@"on_timeupdate" value:pos];
}
- (void)on_seeking
{
    [self call_delegate:@"on_seeking"];
}
- (void)on_seeked
{
    [self call_delegate:@"on_seeked"];
}
- (void)on_error
{
    [self call_delegate:@"on_error"];
}
- (void)perr:(NSString *)perr_id msg:(NSString *)msg
{
    [self call_delegate:@"perr" value:perr_id param:msg];
}

- (void)thumbnails_init:(NSDictionary *)thumb_info
{
    [_thumb startWithInfo:thumb_info];
}

@end
