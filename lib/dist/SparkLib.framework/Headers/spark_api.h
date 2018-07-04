//
//  spark-ios-sdk
//
//  Created by spark on 16/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>
#import "spark_api_interface.h"

typedef NS_ENUM(int, SparkLogLevel) {
    SparkLogLevelDebug = 0,
    SparkLogLevelInfo,
    SparkLogLevelWarning,
    SparkLogLevelError,
    SparkLogLevelCritical
};

// Video info class
@interface SparkVideoItem : NSObject
@property NSURL *_Nonnull url;
@property NSString *_Nullable title;
@property NSString *_Nullable desc;
@property NSURL *_Nullable poster;
@property NSURL *_Nullable videoPoster;
@property NSDecimalNumber *_Nullable duration;
@end

@class SparkLoader;
// Protocol for communication with SparkLib js
@protocol SparkLibJSDelegate
@property(weak, readonly) SparkLoader* _Nullable loader;
-(void)on_play;
-(void)on_pause;
-(void)on_ad_suspend;
-(void)on_ad_restore;
-(void)on_ended;
-(void)on_timeupdate:(NSNumber* _Nonnull)pos;
-(void)on_seeking;
-(void)on_seeked;
-(void)on_error;
-(void)perr:(NSString* _Nonnull)id msg:(NSString* _Nullable)msg;
@end

// Preview-enabled customized view controller.
// Inherit this class in your NotificationContentExtension.
__IOS_AVAILABLE(10.0) __TVOS_PROHIBITED __WATCHOS_PROHIBITED
@interface SparkPreviewNotificationViewController : UIViewController
@end
// Remote notification handler class (remote notifications only).
// Inherit this class in your NotificationServiceExtension.
__IOS_AVAILABLE(10.0) __TVOS_PROHIBITED __WATCHOS_PROHIBITED
@interface SparkPreviewNotificationService : UNNotificationServiceExtension
@end

@interface SparkAPI : NSObject

// Returns SparkAPI singleton instance. First call will initialize SDK, thus
// providing customer id is mandatory. Consequtive calls can omit passing extra
// argument.
//     @param customerId - id used during customer registration on
//         Spark Control Panel (https://holaspark.com/cp)
+ (SparkAPI *_Nonnull)getAPI:(NSString *_Nullable)customerId;

// Configures verbosity logging level (SparkLogLevelError by default).
//     @param level - defines sdk logs >=level to be printed to app console
- (void)setLogLevel:(SparkLogLevel)level;

// Register your application within notification system. Call this method once
// in didFinishLaunchingWithOptions implementation of UIApplicationDelegate
// protocol.
//     @param options - list of authorization options, e.g.:
//         UNAuthorizationOptionAlert|UNAuthorizationOptionSound
//     @param usingRemoteNotifications - defines whether your app targets for
//         both local and remote notifications: YES=local+remote, NO=localonly
//         NOTE: if your app is intended to use remote notifications, you must
//         implement didRegisterForRemoteNotificationsWithDeviceToken and
//         didFailToRegisterForRemoteNotificationsWithError methods of
//         UIApplicationDelegate protocol.
//     @param withCompletionBlock - registration result providing you with
//         error object if operation failed.
- (void)registerForNotifications:(UNAuthorizationOptions)options
    usingRemoteNotifications:(BOOL)remote
    withCompletionBlock:(void (^_Nonnull)(NSError *_Nullable))ondone
    __IOS_AVAILABLE(10.0) __TVOS_PROHIBITED __WATCHOS_PROHIBITED;

// Send local notification with preview for provided video url to the
// notification center.
//     @param forVideoUrl - media resource for which video preview is to be
//         generated and shown in the notification
//     @param withTitle - UNMutableNotificationContent.title
//     @param withSubtitle (optional) - UNMutableNotificationContent.subtitle
//     @param withBody - UNMutableNotificationContent.body
//     @param withTriggerOn - trigger that defines the moment of time when to
//         show this notification to the user, e.g. can be one of:
//         - UNTimeIntervalNotificationTrigger
//         - UNCalendarNotificationTrigger
//         - UNLocationNotificationTrigger
//         - UNPushNotificationTrigger
//     @param withBeforeSendBlock (optional) - code block called after preview
//         is loaded and just before the notification is scheduled to the
//         notification center; use it to perform custom operations upon
//         notification payload. Note: returning "NO" within the code block
//         will not send out the notification, this way you can take the full
//         control over notification yourself.
//     @param withCompletionBlock (optional) - code block called to indicate
//         the status of operation, NSError object will indicate the reason of
//         a failure (preview loading failed, notification unable to schedule
//         etc) or "nil" in case of the success.
- (void)sendPreviewNotification:(NSURL *_Nonnull)forVideoUrl
    withTitle:(NSString *_Nonnull)title
    withSubtitle:(NSString *_Nullable)subtitle
    withBody:(NSString *_Nonnull)body
    withTriggerOn:(UNNotificationTrigger *_Nonnull)trigger
    withBeforeSendBlock:(BOOL (^_Nullable)(
        UNMutableNotificationContent *_Nonnull,
        UNNotificationSettings *_Nonnull))onbeforesend
    withCompletionBlock: (void (^_Nullable)(NSError *_Nullable))ondone
    __IOS_AVAILABLE(10.0) __TVOS_PROHIBITED __WATCHOS_PROHIBITED;

// Retrieve the list of the most popular videos over defined time period.
//     @param hits - number of videos to retrieve (basically a length of
//         video array in completion block)
//     @param overLast - array of periods to retrieve the playlist for.
//         possible input: multiples of "1h", "6h", "1d", "1w", "1m" or
//         "new" to retrieve the list of recently added videos.
//         examples:
//         @[@"3h"] - popular videos over the last 3 hours
//         @[@"1d", @"1w"] - popular videos over the last day and the last week
//     @param withCompletionBlock - code block that will provide the result
//         with the list of videos or error in case of operation failure.
- (NSURLSessionDataTask *_Nonnull)getPopularVideos:(NSUInteger)hits
    overLast:(NSArray<NSString *> *_Nonnull)periods
    withCompletionBlock:(void (^_Nonnull)(
        NSDictionary<NSString *, NSArray<SparkVideoItem *> *> *_Nullable,
        NSError *_Nullable))ondone;

// Register an AVPlayerItem to work with SparkAPI
//     @param forItem - AVPlayerItem to register
- (id<SparkLibJSDelegate> _Nonnull)addPlayerProxy:(AVPlayerItem *_Nonnull)forItem;
- (id<SparkLibJSDelegate> _Nonnull)addPlayerProxy:(AVPlayerItem *_Nonnull)forItem
    andPlayer:(id<SparkLibPlayerDelegate> _Nonnull)player;

// Unregister the AVPlayerItem from SparkAPI
//     @param forItem - AVPlayerItem to unregister
- (void)removePlayerProxy:(AVPlayerItem *_Nonnull)forItem;

// Finalize spark and release resources.
+ (void)finalize;

@end
