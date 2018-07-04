//
//  thumbnails_controller.m
//  SparkLib
//
//  Created by norlin on 28/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "thumbnails_controller.h"
#import "log.h"

@interface ThumbnailsController()
@property(weak, readonly) id<SparkLibPlayerDelegate> player;
@property(weak, readonly) id<SparkThumbnailsDelegate> delegate;
@property SparkLog *log;
@end

@implementation ThumbnailsController
- (instancetype)init_with_player:(id<SparkLibPlayerDelegate>)player
{
    self = [super init];
    if (self)
    {
        _player = player;
        _delegate = nil;
        _log = [SparkLog log_with_module:@"thumbnails"];
        _config = nil;
    }
    return self;
}

- (void)startWithInfo:(NSDictionary *)thumb_info
{
    if (!thumb_info)
        return;
    _config = [[ThumbnailsConfig alloc] init:thumb_info];
    __weak id<SparkThumbnailsHandlerDelegate> weak_self = self;
    _delegate = [_player get_thumbnails_delegate:weak_self];
    [_delegate setWidth:_config.width andHeight:_config.height];
}

- (void)get_state
{
}

- (void)set_state
{
}

- (void)seekStart:(CMTime)pos
{
    [_delegate display];
}

- (void)seekMove:(CMTime)pos
{
}

- (void)seekEnd
{
    [_delegate hide];
}
@end
