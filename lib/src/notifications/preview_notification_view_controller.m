//
//  preview_notification_view_controller.m
//  spark-ios-sdk
//
//  Created by volodymyr on 16/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "preview_notification_view_controller.h"
#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface SparkPreviewNotificationViewController ()
    <UNNotificationContentExtension>

@property UNNotificationAttachment *attachment;
@property AVPlayerLooper *looper;
@property AVPlayerLayer *avlayer;

@end

@implementation SparkPreviewNotificationViewController

- (void)dealloc {
    if (self.attachment)
        [self.attachment.URL stopAccessingSecurityScopedResource];
    if (self.avlayer)
        [self removeObserver:self forKeyPath:@"avlayer.videoRect"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveNotification:(UNNotification *)notification {
    if (notification.request.content.attachments.count<1)
        return;
    UNNotificationAttachment *attachment =
    notification.request.content.attachments.firstObject;
    if (![attachment.URL startAccessingSecurityScopedResource])
        return;
    AVAsset *asset = [AVAsset assetWithURL:attachment.URL];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    AVQueuePlayer *player = [[AVQueuePlayer alloc] init];
    AVPlayerLooper *looper = [AVPlayerLooper
        playerLooperWithPlayer:player templateItem:item];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
    layer.videoGravity = kCAGravityResize;
    // assume 16:9 by default, will resize if different ratio
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width,
        self.view.frame.size.width/16*9);
    [self.view.layer addSublayer:layer];
    [player play];
    self.looper = looper;
    self.avlayer = layer;
    self.attachment = attachment;
    [self addObserver:self forKeyPath:@"avlayer.videoRect"
        options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)ctx
{
    if ([keyPath isEqualToString:@"avlayer.videoRect"])
    {
        CGRect video = [[object valueForKeyPath:keyPath] CGRectValue];
        if (video.size.width==0 ||
            (video.size.width==self.avlayer.frame.size.width &&
            video.size.height==self.avlayer.frame.size.height))
        {
            return;
        }
        int width = self.avlayer.frame.size.width;
        int height = self.avlayer.frame.size.width/
        self.avlayer.videoRect.size.width*self.avlayer.videoRect.size.height;
        self.avlayer.frame = CGRectMake(0, 0, width, height);
        self.view.frame = CGRectMake(0, 0, width, height);
        self.preferredContentSize = CGSizeMake(width, height);
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object
            change:change context:ctx];
    }
}

@end

