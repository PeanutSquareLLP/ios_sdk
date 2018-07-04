//
//  array.m
//  SparkLib
//
//  Created by volodymyr on 07/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import "array.h"

@implementation NSArray (SparkExtension)

- (NSArray *)spark_mapUsingBlock:(id (^)(id obj, NSUInteger idx))block
{
    return [self spark_mapUsingBlock:block filter_empty:NO];
}

- (NSArray *)spark_mapUsingBlock:(id (^)(id obj, NSUInteger idx))block
    filter_empty:(BOOL)filter_empty
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        id mapped_obj = block(obj, idx);
        if (mapped_obj || !filter_empty)
            [result addObject:mapped_obj];
    }];
    return result;
}

@end
