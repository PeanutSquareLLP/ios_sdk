//
//  preview_notification_service.m
//  spark-ios-sdk
//
//  Created by volodymyr on 16/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "preview_notification_service.h"
#import "preview_notification_util.h"
#import "preview_map.h"
#import "log.h"

@interface SparkPreviewNotificationService ()

@property SparkLog *log;
@property (nonatomic, strong) void (^handler)(UNNotificationContent *content);
@property (nonatomic, strong) UNMutableNotificationContent *content;

@end

@implementation SparkPreviewNotificationService

- (instancetype)init
{
    self = [super init];
    _log = [SparkLog log_with_module:@"notif_svc"];
    return self;
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
    withContentHandler:(void (^)(UNNotificationContent * _Nonnull))handler
{
    self.handler = handler;
    self.content = [request.content mutableCopy];
    if (self.content)
    {
        NSString *url, *customer;
        NSDictionary *info = self.content.userInfo;
        // XXX volodymyr: app extension does not share the namespace with its
        // bundled app, so we rely on customer id provided by the notification
        // payload. find a way to share data between app and ext, since using
        // app groups is not suitable as it requires a complicated integration
        // step we would like to avoid
        if (!(customer = info[NOTIFICATION_PAYLOAD_CUSTOMER_KEY]) ||
            !(url = info[NOTIFICATION_PAYLOAD_MEDIA_KEY]))
        {
            return self.handler(self.content);
        }
        [_log debug:@"received remote notification for %@", url];
        UNMutableNotificationContent *content = self.content;
        SparkPreviewMap *preview = [[SparkPreviewMap alloc] init:customer];
        [preview get_preview_url:[NSURL URLWithString:url]
            ondone:^(NSArray<NSURL *> *preview_sources, NSError *error)
        {
            if (error)
            {
                [_log err:@"failed to detect preview url: %@", error];
                self.content = nil; // we did our best
                return;
            }
            [SparkPreviewNotificationUtil
                add_remote_attachment:content using_sources:preview_sources
                oncomplete:^(NSURL *selected, NSError *error){
                    if (error)
                    {
                        [_log err:@"failed to load remote attachment: %@",
                            error];
                        self.content = nil; // we did our best
                        return;
                    }
                    NSMutableDictionary *new_info = [info mutableCopy];
                    [new_info setValue:selected.absoluteString
                        forKey:NOTIFICATION_PAYLOAD_PREVIEW_KEY];
                    self.content.userInfo = new_info;
                    self.handler(self.content);
                }
            ];
        }];
    }
}

- (void)serviceExtensionTimeWillExpire {
    if (self.content)
        self.handler(self.content);
}

@end
