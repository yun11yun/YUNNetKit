//
//  YUNMath.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface YUNMath : NSObject

+ (CGPoint)ceilForPoint:(CGPoint)value;
+ (CGSize)ceilForSize:(CGSize)value;
+ (CGPoint)floorForPoint:(CGPoint)value;
+ (CGSize)floorForSize:(CGSize)value;
+ (NSUInteger)hashWithCGFloat:(CGFloat)value;
+ (NSUInteger)hashWithCString:(const char *)value;
+ (NSUInteger)hashWithDouble:(double)value;
+ (NSUInteger)hashWithFloat:(float)value;
+ (NSUInteger)hashWithInteger:(NSUInteger)value;
+ (NSUInteger)hashWithInteger:(NSUInteger)value1 andInteger:(NSUInteger)value2;
+ (NSUInteger)hashWithIntegerArray:(NSUInteger *)values count:(NSUInteger)count;
+ (NSUInteger)hashWithLong:(unsigned long long)value;
+ (NSUInteger)hashWithPointer:(const void *)value;

@end
