//
//  YUNKeychainStoreViaBundleID.m
//  YUNNetKit
//
//  Created by Orange on 5/13/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNKeychainStoreViaBundleID.h"

#import "YUNDynamicFrameworkLoader.h"
#import "YUNInternalUtility.h"

@implementation YUNKeychainStoreViaBundleID

- (instancetype)init
{
    return [super initWithService:[[NSBundle mainBundle] bundleIdentifier] accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup
{
    return [self init];
}

- (NSMutableDictionary *)queryForKey:(NSString *)key
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)[YUNDynamicFrameworkLoader loadkSecClass]] = (__bridge id)([YUNDynamicFrameworkLoader loadkSecClassGenericPassword]);
    query[(__bridge id)[YUNDynamicFrameworkLoader loadkSecAttrService]] = self.service;
    query[(__bridge id)[YUNDynamicFrameworkLoader loadkSecAttrGeneric]] = key;
#if !TARGET_IPHONE_SIMULATOR
    [FBSDKInternalUtility dictionary:query setObject:self.accessGroup forKey:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessGroup]];
#endif
    
    return query;
}

@end
