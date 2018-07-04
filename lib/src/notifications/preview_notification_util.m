//
//  preview_notification_content.m
//  spark-ios-sdk
//
//  Created by volodymyr on 16/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "preview_notification_util.h"
#import "error.h"
#import "log.h"
#import "util.h"

@implementation SparkPreviewNotificationUtil

+ (void)add_remote_attachment:(UNMutableNotificationContent *)content
    using_url:(NSURL *)url oncomplete:(void (^)(NSError *))oncomplete
{
    SparkLog *log = [SparkLog log_with_module:@"notifications"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [SparkUtil add_base_http_headers:request];
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error)
    {
        NSHTTPURLResponse *_resp = (NSHTTPURLResponse *)resp;
        if (error)
            [log err:@"remote resource unavailable: error %@", error];
        else if (_resp.statusCode!=200)
        {
            NSString *debug = [[NSString alloc] initWithData:data
                encoding:NSASCIIStringEncoding];
            [log info:@"remote resource unavailable: server returned %ld "
                 @"with %@", (long)_resp.statusCode, debug];
            error = [SparkError code2error:spark_err_preview_load_failed
                with_desc:@"server returned %ld with %@",
                (long)_resp.statusCode, debug];
        }
        else
        {
            @try {
                NSURL *location = [SparkUtil gen_unique_tmp_file:@"preview"
                    with_ext:url.pathExtension];
                [data writeToURL:location atomically:YES];
                UNNotificationAttachment *attachment =
                    [UNNotificationAttachment
                    attachmentWithIdentifier:@"remote"
                    URL:location options:nil error:nil];
                content.attachments = @[attachment];
            }
            @catch (NSException *e){
                [log err:@"failed to save remote resource: '%@'", e];
                error = [SparkError code2error:spark_err_preview_attach_failed
                    with_desc:@"unable to save remote resource: '%@'", e];
            }
        }
        oncomplete(error);
    }];
    [task resume];
};

+ (void)add_remote_attachment:(UNMutableNotificationContent *)content
    using_sources:(NSArray<NSURL *> *)sources
    oncomplete:(void (^)(NSURL *, NSError *))oncomplete
{
    SparkLog *log = [SparkLog log_with_module:@"notifications"];
    NSMutableDictionary *info = [[NSMutableDictionary alloc]
        initWithCapacity:sources.count];
    typedef void(^try_next_block_t)(NSUInteger index);
    try_next_block_t try_next;
    __block __weak try_next_block_t try_next_weak;
    try_next_weak = try_next = ^(NSUInteger index){
        if (index>=sources.count)
        {
            [log err:@"all remote resources failed"];
            return oncomplete(nil, [SparkError
                code2error:spark_err_preview_load_failed
                with_info:info with_desc:@"all remote resources failed"]);
        }
        // avoid retain cycle, but keep the block until all cycles complete
        try_next_block_t try_next_strong = try_next_weak;
        [log info:@"loading remote resource from %@", sources[index]];
        [SparkPreviewNotificationUtil add_remote_attachment:content
            using_url:sources[index] oncomplete:^(NSError *err)
        {
            if (!err)
                return oncomplete(sources[index], nil);
            [info setValue:err forKey:sources[index].absoluteString];
            try_next_strong(index+1);
        }];
    };
    try_next(0);
}

@end
