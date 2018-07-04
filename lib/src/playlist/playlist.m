//
//  playlist.m
//  SparkLib
//
//  Created by volodymyr on 09/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "playlist.h"
#import "array.h"
#import "error.h"
#import "log.h"
#import "util.h"

@implementation SparkVideoItem
@synthesize url;
@synthesize title;
@synthesize desc;
@synthesize poster;
@synthesize videoPoster;
@synthesize duration;

- (NSString *)description
{
    return [NSString stringWithFormat:@"SparkVideoItem<%@%@%@%@%@%@>",
        url ? @"url" : @"", title ? @",title" : @"", desc ? @",desc" : @"",
        poster ? @",poster" : @"", videoPoster ? @",videoPoster" : @"",
        duration ? @",duration" : @""];
}

@end

@implementation SparkPlaylist

+ (NSURLSessionDataTask *)getVideos:(NSString *)customer
    hits:(NSUInteger)hits over_last:(NSArray<NSString *> *)periods
    ondone:(void (^)(
        NSDictionary<NSString *, NSArray<SparkVideoItem *> *> *,
        NSError *))ondone;
{
    SparkLog *log = [SparkLog log_with_module:@"playlist"];
    NSURL *url = [SparkUtil get_spark_cmd_url:@"get_playlists"
        with_customer:customer
        with_query:@[
            [NSURLQueryItem queryItemWithName:@"last"
                value:[periods componentsJoinedByString:@"+"]],
            [NSURLQueryItem queryItemWithName:@"hits"
                value:[NSString stringWithFormat:@"%lu", (unsigned long)hits]],
            [NSURLQueryItem queryItemWithName:@"vinfo" value:@"1"],
            [NSURLQueryItem queryItemWithName:@"ext" value:@"1"]
        ]];
    [log info:@"loading playlist with latest %@ videos from %@",
        [periods componentsJoinedByString:@"+"], url.absoluteString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [SparkUtil add_base_http_headers:request];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error)
    {
        if (error)
        {
            [log err:@"playlist api failed: %@", error];
            return ondone(nil, error);
        }
        NSHTTPURLResponse *_resp = (NSHTTPURLResponse *)resp;
        long code = (long)_resp.statusCode;
        if (code!=200)
        {
            [log err:@"playlist load failed: server returned %ld with %@",
                code, [SparkUtil data2str:data limit_to:100]];
            return ondone(nil, [SparkError
                code2error:spark_err_playlist_api_failed
                with_desc:@"server returned %ld", code]);
        }
        NSError *parse_error = nil;
        NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data
            options:0 error:&parse_error];
        if (parse_error)
        {
            [log err:@"playlist api failed: non-json server response: '%@'",
                code, [SparkUtil data2str:data limit_to:200]];
            return ondone(nil, [SparkError
                code2error:spark_err_playlist_api_failed
                with_desc:@"non-json server response"]);
        }
        NSMutableDictionary *result = [NSMutableDictionary
            dictionaryWithCapacity:periods.count];
        @try {
            NSString *key;
            NSEnumerator *enumerator = [[root allKeys] objectEnumerator];
            while (key = [enumerator nextObject])
            {
                NSArray *videos = [root[key] spark_mapUsingBlock:
                    ^id(id item, NSUInteger idx)
                {
                    NSDictionary *info = item[@"video_info"];
                    if (!info)
                        return nil;
                    SparkVideoItem *video = [[SparkVideoItem alloc] init];
                    video.url =
                        [SparkUtil get_fixed_url_using_str:info[@"url"]];
                    video.title = info[@"title"];
                    video.desc = info[@"description"];
                    video.duration = info[@"dur"];
                    video.poster = [SparkUtil
                        get_fixed_url_using_str:info[@"poster"]];
                    video.videoPoster = [SparkUtil
                        get_fixed_url_using_str:info[@"video_poster"]];
                    return video;
                } filter_empty:YES];
                if (!videos)
                    videos = @[];
                // XXX volodymyr: api/get_playlists returns static list for
                // sparkdemo customer with a single object: customer_popular_1w
                // fix this static list to match the requested ?last= param
                if ([customer isEqualToString:@"sparkdemo"])
                {
                    NSEnumerator *p_enumerator = [periods objectEnumerator];
                    while (key = [p_enumerator nextObject])
                    {
                        [result setValue:videos forKey:[NSString
                            stringWithFormat: @"customer_popular_%@", key]];
                    }
                }
                else
                    [result setValue:videos forKey:key];
            }
        }
        @catch (NSException *e){
            [log err:@"failed to parse server response: '%@'", e];
            return ondone(nil, [SparkError
                code2error:spark_err_playlist_api_failed
                with_desc:@"failed to parse server response"]);
        }
        ondone(result, nil);
    }];
    [task resume];
    return task;
}

@end
