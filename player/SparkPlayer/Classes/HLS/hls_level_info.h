//
//  hola_hls_level_info.h
//  hola-cdn-sdk
//
//  Created by alexeym on 29/07/16.
//  Copyright © 2017 hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "hls_segment_info.h"

@class HolaHLSSegmentInfo;

@interface HolaHLSLevelInfo : NSObject

@property NSString* url;
@property NSNumber* bitrate;
@property NSString* resolution;

@property NSMutableArray<HolaHLSSegmentInfo*>* segments;

-(NSDictionary*)getInfo;

@end
