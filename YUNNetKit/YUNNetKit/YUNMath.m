//
//  YUNMath.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNMath.h"
#import "YUNMacros.h"

@implementation YUNMath

#pragma mark - Class Methods

+ (CGPoint)ceilForPoint:(CGPoint)value
{
    return CGPointMake(ceilf(value.x), ceilf(value.x));
}

+ (CGSize)ceilForSize:(CGSize)value
{
    return CGSizeMake(ceilf(value.width), ceilf(value.height));
}

+ (CGPoint)floorForPoint:(CGPoint)value
{
    return CGPointMake(floorf(value.x), floorf(value.y));
}

+ (CGSize)floorForSize:(CGSize)value
{
    return CGSizeMake(floorf(value.width), floorf(value.height));
}

+ (NSUInteger)hashWithCGFloat:(CGFloat)value
{
#if CGFLOAT_IS_DOUBLE
    return [self hashWithDouble:value];
#else
    return [self hashWithFloat:value];
#endif
}

+ (NSUInteger)hashWithCString:(const char *)value
{
    // FNV-1a hash.
    NSUInteger hash = sizeof(NSUInteger) == 4 ? 2166136261U : 14695981039346656037U;
    while (*value) {
        hash ^= *value++;
        hash *= sizeof(NSUInteger) == 4 ? 16777619 : 1099511628211;
    }
    return hash;
}

+ (NSUInteger)hashWithDouble:(double)value
{
    assert(sizeof(double) == sizeof(uint64_t)); // Size of double must be 8 bytes
    union {
        double key;
        uint64_t bits;
    } u;
    u.key = value;
    return [self hashWithLong:u.bits];
}

+ (NSUInteger)hashWithFloat:(float)value
{
    assert(sizeof(float) == sizeof(uint32_t)); // Size of float must be 4 bytes
    union {
        float key;
        uint32_t bits;
    } u;
    u.key = value;
    return [self hashWithInteger:u.bits];
}

+ (NSUInteger)hashWithInteger:(NSUInteger)value
{
    return [self hashWithPointer:(void *)value];
}

+ (NSUInteger)hashWithInteger:(NSUInteger)value1 andInteger:(NSUInteger)value2
{
    return [self hashWithLong:(((unsigned long long)value1) << 32 | value2)];
}

+ (NSUInteger)hashWithIntegerArray:(NSUInteger *)values count:(NSUInteger)count
{
    if (count == 0) {
        return 0;
    }
    NSUInteger hash = values[0];
    for (NSUInteger i = 1; i < count; ++i) {
        hash = [self hashWithInteger:hash andInteger:values[i]];
    }
    return hash;
}

+ (NSUInteger)hashWithLong:(unsigned long long)value
{
    value = (~value) + (value << 18); // key = (key << 18) - key - 1;
    value ^= (value >> 31);
    value *= 21;                      // key = (key + (key << 2)) + (key << 4);
    value ^= (value >> 11);
    value += (value << 6);
    value ^= (value >> 22);
    return (NSUInteger)value;
}

+ (NSUInteger)hashWithPointer:(const void *)value
{
    NSUInteger hash = (NSUInteger)value;
#if !TARGET_RT_64_BIT
    hash = ~hash + (hash << 15);  // key = (key << 15) - key - 1;
    hash ^= (hash >> 12);
    hash += (hash << 2);
    hash ^= (hash >> 4);
    hash *= 2057;                 // key = (key + (key << 3)) + (key << 11);
    hash ^= (hash >> 16);
#else
    hash += ~hash + (hash << 21);               // key = (key << 21) - key - 1;
    hash ^= (hash >> 24);
    hash = (hash + (hash << 3)) + (hash << 8);
    hash ^= (hash >> 14);
    hash = (hash + (hash << 2)) + (hash << 4);  // key * 21
    hash ^= (hash >> 28);
    hash += (hash << 31);
#endif
    return hash;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

@end
