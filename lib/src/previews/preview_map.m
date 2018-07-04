//
//  preview_map.m
//  spark-ios-sdk
//
//  Created by volodymyr on 19/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "preview_map.h"
#import "error.h"
#import "array.h"
#import "log.h"
#import "util.h"

NSString *preview_api_format =
    @"https://holaspark-demo.h-cdn.com/api/get_previews?customer=%@";
NSString *preview_req_format =
    @"{\"items\": [{\"type\": \"video\", \"url\": \"%@\"}]}";

@interface SparkPreviewMap ()
@property (copy) NSString *customer;
@property SparkLog *log;
@end

@implementation SparkPreviewMap

- (SparkPreviewMap *)init: (NSString *)customer_id
{
    _customer = customer_id;
    _log = [SparkLog log_with_module:@"preview"];
    return self;
}

- (void)get_preview_url: (NSURL *)video_url
    ondone:(void(^)(NSArray<NSURL *> *preview_sources, NSError *error))ondone
{
    [_log info:@"loading preview sources for %@", video_url];
    NSString *data_s = [NSString stringWithFormat:preview_req_format,
        video_url.absoluteString];
    NSString *url_s = [NSString stringWithFormat:preview_api_format,
        self.customer];
    NSURL *url = [NSURL URLWithString:url_s];
    NSData *data = [data_s dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [SparkUtil add_base_http_headers:request];
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error)
    {
        if (error)
        {
            [_log err:@"preview map failed: %@", error];
            return ondone(nil, error);
        }
        NSString *debug = [SparkUtil data2str:data limit_to:100];
        NSHTTPURLResponse *_resp = (NSHTTPURLResponse *)resp;
        long code = (long)_resp.statusCode;
        if (code!=200)
        {
            [_log err:@"preview map failed: server returned %ld with '%@'",
                code, debug];
            return ondone(nil, [SparkError
                code2error:spark_err_preview_map_failed
                with_desc:@"server returned %ld: '%@'", code, debug]);
        }
        NSError *parse_error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data
            options:0 error:&parse_error];
        if (parse_error)
        {
            [_log err:@"preview map failed: non-json server response: '%@'",
                code, debug];
            return ondone(nil, [SparkError
                code2error:spark_err_preview_map_failed
                with_desc:@"non-json server response: '%@'", debug]);
        }
        NSArray<NSURL *> *previews;
        @try {
            NSDictionary *jresult = object;
            if (jresult[@"error"])
            {
                [_log err:@"server returned: '%@'", jresult[@"error"]];
                return ondone(nil, [SparkError
                    code2error:spark_err_preview_map_failed
                    with_desc:@"server returned: '%@'", jresult[@"error"]]);
            }
            NSDictionary *item = jresult[video_url.absoluteString];
            NSString *path = item[@"url"];
            NSArray *cdns = item[@"cdns"];
            previews = [cdns spark_mapUsingBlock:^id(id obj, NSUInteger idx){
                NSURL *url = [NSURL URLWithString:[NSString
                    stringWithFormat:@"https://%@%@", obj[@"hostname"], path]];
                if (!url)
                {
                    @throw [NSException
                        exceptionWithName:NSInternalInconsistencyException
                        reason:nil userInfo:nil];
                }
                return url;
            }];
            [_log info:@"previews found on %ld cdn(s): %@", cdns.count,
                [[cdns spark_mapUsingBlock:^id(id obj, NSUInteger idx){
                return obj[@"hostname"]; }] componentsJoinedByString:@", "]];
        }
        @catch (NSException *e){}
        if (!previews)
        {
            [_log err:@"unrecognized server response: '%@'", debug];
            return ondone(nil, [SparkError
                code2error:spark_err_preview_map_failed
                with_desc:@"unrecognized server response: '%@'", debug]);
        }
        ondone(previews, nil);
    }];
    [task resume];
}

@end
