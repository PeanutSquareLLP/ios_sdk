//
//  preview_notification_content.m
//  spark-ios-sdk
//
//  Created by volodymyr on 16/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

#define NOTIFICATION_PAYLOAD_MEDIA_KEY @"spark-media-url"
#define NOTIFICATION_PAYLOAD_PREVIEW_KEY @"spark-preview-url"
#define NOTIFICATION_PAYLOAD_CUSTOMER_KEY @"spark-customer-id"

__IOS_AVAILABLE(10.0) __TVOS_PROHIBITED __WATCHOS_PROHIBITED
@interface SparkPreviewNotificationUtil: NSObject

+ (void)add_remote_attachment:(UNMutableNotificationContent *)content
    using_url:(NSURL *)url oncomplete:(void (^)(NSError *))oncomplete;

+ (void)add_remote_attachment:(UNMutableNotificationContent *)content
    using_sources:(NSArray<NSURL *> *)sources
    oncomplete:(void (^)(NSURL *, NSError *))oncomplete;


@end
