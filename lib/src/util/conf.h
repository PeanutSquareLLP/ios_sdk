//
//  conf.h
//  SparkLib
//
//  Created by volodymyr on 03/04/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SparkConf : NSObject

- (instancetype)init:(NSDictionary *)source;
- (instancetype)get_subconf:(NSString *)path;

- (id)get_raw:(NSString *)path;
- (id)get_raw:(NSString *)path with_default:(id)def;

- (NSString *)get_str:(NSString *)path;
- (NSString *)get_str:(NSString *)path with_default:(NSString *)def;

- (NSNumber *)get_number:(NSString *)path;
- (NSNumber *)get_number:(NSString *)path with_default:(NSNumber *)def;

- (BOOL)get_bool:(NSString *)path;
- (BOOL)get_bool:(NSString *)path with_default:(BOOL)def;

@end
