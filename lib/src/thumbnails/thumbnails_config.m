//
//  thumbnails_config.m
//  SparkLib
//
//  Created by alexeym on 05/04/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "thumbnails_config.h"

@implementation ThumbnailsConfig
- (instancetype)init:(NSDictionary *)thumb_info
{
    self = [super init];
    if (self) {
        @try {
            NSDictionary *info = [thumb_info valueForKey:@"info"];
            NSArray<NSDictionary *> *cdn_info =
                [thumb_info valueForKey:@"cdns"];
            NSMutableArray<NSString *> *cdns = [[NSMutableArray alloc]
                initWithCapacity:[cdn_info count]];
            for (NSDictionary *cdn in cdns)
            {
                NSString *host = [cdn valueForKey:@"host"];
                [cdns addObject:host];
            }
            _cdns = cdns.copy;
            _urls = [thumb_info valueForKey:@"urls"];
            _width = [info valueForKey:@"width"];
            _height = [info valueForKey:@"height"];
            _group_size = [info valueForKey:@"group_size"];
            _interval = [info valueForKey:@"interval"];
        }
        @catch (NSException *exception) {
            // XXX alexeym: log error
        }
    }
    return self;
}
@end
