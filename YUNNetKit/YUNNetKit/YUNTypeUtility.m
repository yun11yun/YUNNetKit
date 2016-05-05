//
//  YUNTypeUtility.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNTypeUtility.h"

#import "YUNMacros.h"

@implementation YUNTypeUtility

#pragma mark - Class Methods

+ (NSArray *)arrayValue:(id)object
{
    return (NSArray *)[self _objectValue:object ofClass:[NSArray class]];
}

+ (BOOL)boolValue:(id)object
{
    if ([object isKindOfClass:[NSNumber class]]) {
        // @0 or @NO returns NO, otherwise YES
        return [(NSNumber *)object boolValue];
    } else if ([object isKindOfClass:[NSString class]]) {
        // Returns YES on encountering one of "Y", "y", "T", "t", or a digit 1-9, otherwise NO
        return [(NSString *)object boolValue];
    } else {
        return ([self objectValue:object] != nil);
    }
}

+ (NSDictionary *)dictionaryValue:(id)object
{
    return (NSDictionary *)[self _objectValue:object ofClass:[NSDictionary class]];
}

+ (NSInteger)integerValue:(id)object
{
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object integerValue];
    } else if ([object isKindOfClass:[NSString class]]) {
        return [(NSString *)object integerValue];
    } else {
        return 0;
    }
}

+ (id)objectValue:(id)object
{
    return ([object isKindOfClass:[NSNull class]] ? nil : object);
}

+ (NSString *)stringValue:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object stringValue];
    } else if ([object isKindOfClass:[NSURL class]]) {
        return [(NSURL *)object absoluteString];
    } else {
        return nil;
    }
}

+ (NSUInteger)unsignedIntegerValue:(id)object
{
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object unsignedIntegerValue];
    } else {
        // there is no direct support for strings containing unsigned values > NSIntegerMax - not worth writing ourselves
        // right now, so just cap unsigned values at NSIntegerMax until we have a need for larger
        NSInteger integerValue = [self integerValue:object];
        if (integerValue < 0) {
            integerValue = 0;
        }
        return (NSUInteger)integerValue;
    }
}

+ (NSURL *)URLValue:(id)object
{
    if ([object isKindOfClass:[NSURL class]]) {
        return (NSURL *)object;
    } else if ([object isKindOfClass:[NSString class]]) {
        return [[NSURL alloc] initWithString:(NSString *)object];
    } else {
        return nil;
    }
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

#pragma mark - Helper Methods

+ (id)_objectValue:(id)object ofClass:(Class)expectedClass
{
    return ([object isKindOfClass:expectedClass] ? object : nil);
}

@end
