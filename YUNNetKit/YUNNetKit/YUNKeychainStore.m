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

- (BOOL)setData:(NSData *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility
{
    if (!key) {
        return NO;
    }
    
    NSMutableDictionary *query = [self queryForKey:key];
    
    OSStatus status;
    if (value) {
        NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
        [attributesToUpdate setObject:value forKey:[YUNDynamicFrameworkLoader loadkSecValueData]];
        
        status = yundfl_SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
        if (status == errSecItemNotFound) {
#if TARGET_OS_IPHONE || (defined(MAC_OS_X_VERSION_10_9) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9)
            if (accessibility) {
                [query setObject:(__bridge id)(accessibility) forKey:[YUNDynamicFrameworkLoader loadkSecAttrAccessible]];
            }
#endif
            [query setObject:value forKey:[YUNDynamicFrameworkLoader loadkSecValueData]];
            
            status = yundfl_SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        }
    } else {
        status = yundfl_SecItemDelete((__bridge CFDictionaryRef)query);
        if (status == errSecItemNotFound) {
            status = errSecSuccess;
        }
    }
    
    return (status == errSecSuccess);
}

- (NSData *)dataForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    NSMutableDictionary *query = [self queryForKey:key];
    [query setObject:(id)kCFBooleanTrue forKey:[YUNDynamicFrameworkLoader loadkSecReturnData]];
    [query setObject:[YUNDynamicFrameworkLoader loadkSecMatchLimitOne] forKey:[YUNDynamicFrameworkLoader loadkSecMatchLimit]];
    
    CFTypeRef data = nil;
    OSStatus status = yundfl_SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
    if (status != errSecSuccess) {
        return nil;
    }
    
    if (!data || CFGetTypeID(data) != CFDataGetTypeID()) {
        return nil;
    }
    
    NSData *ret = [NSData dataWithData:(__bridge NSData *)(data)];
    CFRelease(data);
    
    return ret;
}

- (NSMutableDictionary *)queryForKey:(NSString *)key
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:[YUNDynamicFrameworkLoader loadkSecClassGenericPassword] forKey:[YUNDynamicFrameworkLoader loadkSecClass]];
    [query setObject:_service forKey:[YUNDynamicFrameworkLoader loadkSecAttrService]];
    [query setObject:key forKey:[YUNDynamicFrameworkLoader loadkSecAttrAccount]];
#if !TARGET_IPHONE_SIMULATOR
    if (_accessGroup) {
        [query setObject:_accessGroup forKey:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessGroup]];
    }
#endif
    
    return query;
}

@end
