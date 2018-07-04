//
//  spark_api.m
//  spark-ios-sdk
//
//  Created by volodymyr on 16/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "spark_api.h"
#import "loader.h"
#import "error.h"
#import "preview_map.h"
#import "playlist.h"
#import "preview_notification_util.h"
#import "log.h"
#import <UIKit/UIKit.h>

SparkAPI *singleton = nil;

@interface SparkAPI ()
@property (copy) NSString *customer;
@property SparkLoader *loader;
@end

@implementation SparkAPI

+ (SparkAPI *)getAPI: (NSString *)customerId
{
    NSString *ereason;
    if (singleton)
    {
        if (customerId && customerId!=singleton.customer)
        {
            ereason = @"SparkSDK already initialized with customer id \"%@\". "
                @"If you wish to change customer id to \"%@\", uninit "
                @"previous instance with finalize call first.";
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                reason:[NSString stringWithFormat:ereason, singleton.customer,
                customerId] userInfo:nil];
        }
        return singleton;
    }
    if (!customerId)
    {
        ereason = @"SparkSDK first init: customer id required";
        @throw [NSException exceptionWithName:NSInvalidArgumentException
            reason:ereason userInfo:nil];
    }
    singleton = [SparkAPI alloc];
    singleton.customer = customerId;
    singleton.loader = [[SparkLoader alloc] init:singleton.customer];
    return singleton;
}

- (void)setLogLevel:(SparkLogLevel)level
{
    [self _assert_if_not_inited];
    [SparkLog set_verbose_level:level];
}

- (void)registerForNotifications: (UNAuthorizationOptions)options
    usingRemoteNotifications: (BOOL)remote
    withCompletionBlock: (void (^)(NSError *error))ondone
{
    [self _assert_if_not_inited];
    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions: options
        completionHandler:^(BOOL granted, NSError *error)
    {
        if (!granted)
        {
            if (!error)
                error = [SparkError code2error:spark_err_notif_no_auth];
            return ondone(error);
        }
        if (!remote)
            return ondone(nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIApplication *app = UIApplication.sharedApplication;
            [app registerForRemoteNotifications];
            ondone(nil);
        });
    }];
    UNNotificationCategory *category = [UNNotificationCategory
        categoryWithIdentifier:@"spark-preview" actions:@[]
        intentIdentifiers:@[]
        options:UNNotificationCategoryOptionCustomDismissAction];
    [center setNotificationCategories:[NSSet setWithObject:category]];
}

- (void)sendPreviewNotification: (NSURL *)forVideoUrl
    withTitle: (NSString *)title
    withSubtitle: (NSString *)subtitle
    withBody: (NSString *)body
    withTriggerOn: (UNNotificationTrigger *)trigger
    withBeforeSendBlock: (BOOL (^)(UNMutableNotificationContent *,
        UNNotificationSettings *))onbeforesend
    withCompletionBlock: (void (^)(NSError *))ondone
{
    [self _assert_if_not_inited];
    if (!ondone)
        ondone = ^(NSError *error){};
    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:
        ^(UNNotificationSettings *settings)
    {
        if (settings.authorizationStatus!=UNAuthorizationStatusAuthorized)
            return ondone([SparkError code2error:spark_err_notif_no_auth]);
        UNMutableNotificationContent *content =
            [[UNMutableNotificationContent alloc] init];
        content.categoryIdentifier = @"spark-preview";
        content.title = title;
        if (subtitle)
            content.subtitle = subtitle;
        content.body = body;
        if (settings.soundSetting==UNNotificationSettingEnabled)
            content.sound = UNNotificationSound.defaultSound;
        if (settings.badgeSetting==UNNotificationSettingEnabled)
            content.badge = [NSNumber numberWithInt:1];
        void (^send_notification)(void) = ^(){
            if (onbeforesend && !onbeforesend(content, settings))
                return; // customer has overriden our send logic
            UNNotificationRequest *request = [UNNotificationRequest
                requestWithIdentifier:@"spark-preview-request"
                content:content trigger:trigger];
            [center addNotificationRequest:request withCompletionHandler:
                ^(NSError *error){ ondone(error); }];
        };
        if ([forVideoUrl.scheme isEqualToString:@"file"])
        {
            content.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                forVideoUrl.absoluteString, NOTIFICATION_PAYLOAD_PREVIEW_KEY,
                self.customer, NOTIFICATION_PAYLOAD_CUSTOMER_KEY, nil];
            UNNotificationAttachment *attachment = [UNNotificationAttachment
                attachmentWithIdentifier:@"local"
                URL:forVideoUrl options:nil error:nil];
            content.attachments = @[attachment];
            return send_notification();
        }
        SparkPreviewMap *preview =
            [[SparkPreviewMap alloc] init:self.customer];
        [preview get_preview_url:forVideoUrl
            ondone:^(NSArray<NSURL *> *preview_sources, NSError *error)
        {
            if (error)
                return ondone(error);
            [SparkPreviewNotificationUtil add_remote_attachment:content
                using_sources:preview_sources
                oncomplete:^(NSURL *selected, NSError *error)
            {
                if (error)
                    return ondone(error);
                content.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    forVideoUrl.absoluteString, NOTIFICATION_PAYLOAD_MEDIA_KEY,
                    selected.absoluteString, NOTIFICATION_PAYLOAD_PREVIEW_KEY,
                    self.customer, NOTIFICATION_PAYLOAD_CUSTOMER_KEY, nil];
                send_notification();
            }];
         }];
    }];
}

- (NSURLSessionDataTask *_Nonnull)getPopularVideos:(NSUInteger)hits
    overLast:(NSArray<NSString *> *_Nonnull)periods
    withCompletionBlock:(void (^_Nonnull)(
        NSDictionary<NSString *, NSArray<SparkVideoItem *> *> *_Nullable,
        NSError *_Nullable))ondone
{
    [self _assert_if_not_inited];
    return [SparkPlaylist getVideos:self.customer hits:hits over_last:periods
        ondone:ondone];
}

- (id<SparkLibJSDelegate>)addPlayerProxy:(AVPlayerItem *)forItem
{
    [self _assert_if_not_inited];
    return [singleton.loader add_player_proxy:forItem player:nil];
}

- (id<SparkLibJSDelegate>)addPlayerProxy:(AVPlayerItem *)forItem
    andPlayer:(id<SparkLibPlayerDelegate>)player
{
    [self _assert_if_not_inited];
    return [singleton.loader add_player_proxy:forItem player:player];
}

- (void)removePlayerProxy:(AVPlayerItem *)forItem
{
    [self _assert_if_not_inited];
    [singleton.loader remove_player_proxy:forItem];
}

+ (void)finalize
{
    if (!singleton)
        return;
    if (singleton.loader)
        [singleton.loader uninit];
    singleton.customer = nil;
    singleton = nil;
}

- (void)_assert_if_not_inited
{
    if (!_customer)
    {
        @throw [NSException exceptionWithName:NSGenericException
            reason:@"SparkAPI instance not initialized, use getAPI method "
            @"to access spark library API" userInfo:nil];
    }
}

@end
