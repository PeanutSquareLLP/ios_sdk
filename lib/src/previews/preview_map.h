//
//  preview_map.h
//  spark-ios-sdk
//
//  Created by volodymyr on 19/02/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SparkPreviewMap : NSObject

- (SparkPreviewMap *)init: (NSString *)customer_id;

- (void)get_preview_url: (NSURL *)video_url
  ondone:(void(^)(NSArray<NSURL *> *preview_sources, NSError *error))ondone;

@end
