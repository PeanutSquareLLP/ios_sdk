//
//  stats.h
//  SparkLib
//
//  Created by volodymyr on 03/04/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SparkStats

- (NSNumber *)get:(NSString *)name;
- (void)set:(NSString *)name to:(NSNumber *)value;

- (void)inc:(NSString *)name;
- (void)inc:(NSString *)name by:(NSNumber *)increment;

@end
