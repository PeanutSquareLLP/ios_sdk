//
//  array.h
//  SparkLib
//
//  Created by volodymyr on 07/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (SparkExtension)

- (NSArray *)spark_mapUsingBlock:(id (^)(id obj, NSUInteger idx))block;
- (NSArray *)spark_mapUsingBlock:(id (^)(id obj, NSUInteger idx))block
    filter_empty:(BOOL)filter_empty;

@end
