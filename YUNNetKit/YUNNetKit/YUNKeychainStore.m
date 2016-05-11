//
//  YUNKeychainStore.m
//  YUNNetKit
//
//  Created by Orange on 5/11/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNKeychainStore.h"

#import "YUNDynamicFrameworkLoader.h"
#import "YUNMacros.h"

@implementation YUNKeychainStore

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup
{
    if ((self = [super init])) {
        _service = service ? [service copy] : [[NSBundle mainBundle] bundleIdentifier];
        _accessGroup = [accessGroup copy];
        NSAssert(_service, @"Keychain must be initialized with service");
    }
    return self;
}
- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithService:accessGroup:);
    return [self initWithService:nil accessGroup:nil];
}

- (BOOL)setDictionary:(NSDictionary *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility
{
    NSData *data = value == nil ? nil : [NSKeyedArchiver archivedDataWithRootObject:value];
    return [self setData:data forKey:key accessibility:accessibility];
}

- (NSDictionary *)dictionarayForKey:(NSString *)key
{
    NSData *data = [self dataForKey:key];
    if (!data) {
        return nil;
    }
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return dict;
}

- (BOOL)setString:(NSString *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility
{
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [self setData:data forKey:key accessibility:accessibility];
}

- (NSString *)stringForKey:(NSString *)key
{
    NSData *data = [self dataForKey:key];
    if (!data) {
        return nil;
    }
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}



@end
