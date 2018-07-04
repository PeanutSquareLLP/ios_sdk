//
//  window_timers.h
//  SparkLib
//
//  https://github.com/Lukas-Stuehrk/WindowTimers
//
//  Created by alexeym on 04/08/16.
//  Copyright © 2017 hola. All rights reserved.
//
//  NOTE: This file copied from HolaCDN ios_sdk with minimum modifications.
//  Entire loader submodule will be reused by HolaCDN once added to SparkLib.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface WTWindowTimers: NSObject

- (void)extend:(id)context;

@property (nonatomic) NSUInteger tolerance;
@property (readonly, nonatomic) id setTimeout;
@property (readonly, nonatomic) id clearTimeout;
@property (readonly, nonatomic) id setInterval;

@end
