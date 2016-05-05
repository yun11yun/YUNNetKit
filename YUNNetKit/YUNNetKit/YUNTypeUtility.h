//
//  YUNTypeUtility.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUNTypeUtility : NSObject

+ (NSArray *)arrayValue:(id)object;
+ (BOOL)boolValue:(id)object;
+ (NSDictionary *)dictionaryValue:(id)object;
+ (NSInteger)integerValue:(id)object;
+ (id)objectValue:(id)object;
+ (NSString *)stringValue:(id)object;
+ (NSUInteger)unsignedIntegerValue:(id)object;
+ (NSURL *)URLValue:(id)object;

@end
