//
//  YUNAccessTokenCacheV3_17.m
//  YUNNetKit
//
//  Created by Orange on 5/13/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAccessTokenCacheV3_17.h"

#import "YUNAccessToken.h"
#import "YUNAccessTokenCacheV3.h"
#import "YUNDynamicFrameworkLoader.h"
#import "YUNKeychainStoreViaBundleID.h"
#import "YUNSettings.h"

@implementation YUNAccessTokenCacheV3_17
{
    YUNKeychainStoreViaBundleID *_keychainStore;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _keychainStore = [[YUNKeychainStoreViaBundleID alloc] init];
    }
    return self;
}

- (YUNAccessToken *)fetchAccessToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuidKey = [[YUNSettings legacyUserDefaultTokenInformationKeyName] stringByAppendingString:@"UUID"];
    NSString *uuid = [defaults objectForKey:uuidKey];
    NSDictionary *tokenDictionary = [_keychainStore dictionarayForKey:[YUNSettings legacyUserDefaultTokenInformationKeyName]];
    if (![tokenDictionary[YUNTokenInforamtionUUIDKey] isEqualToString:uuid]) {
        [self clearCache];
    }
    
    return [YUNAccessTokenCacheV3 accessTokenForV3Dictionary:tokenDictionary];
}

- (void)clearCache
{
    [_keychainStore setDictionary:nil forKey:[YUNSettings legacyUserDefaultTokenInformationKeyName] accessibility:nil];
}

- (void)cacheAccessToken:(YUNAccessToken *)token
{
    // no-op.
    NSAssert(NO, @"deprecated cache YUNAccessToeknCacheV3_17 should not be to cache a token");
}

@end
