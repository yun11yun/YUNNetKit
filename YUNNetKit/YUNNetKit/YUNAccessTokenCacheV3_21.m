//
//  YUNAccessTokenCacheV3_21.m
//  YUNNetKit
//
//  Created by Orange on 5/13/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAccessTokenCacheV3_21.h"

#import "YUNAccessToken.h"
#import "YUNAccessTokenCacheV3.h"
#import "YUNDynamicFrameworkLoader.h"
#import "YUNKeychainStore.h"
#import "YUNSettings.h"

@implementation YUNAccessTokenCacheV3_21
{
    YUNKeychainStore *_keychainStore;
}

- (instancetype)init
{
    if ((self = [super init])) {
        NSString *keyChainServiceIdentifier = [NSString stringWithFormat:@"com.facebook.sdk.tokencache.%@", [[NSBundle mainBundle] bundleIdentifier]];
        _keychainStore = [[YUNKeychainStore alloc] initWithService:keyChainServiceIdentifier accessGroup:nil];
    }
    return self;
}

- (YUNAccessToken *)fetchAccessToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuidKey = [YUNSettings legacyUserDefaultTokenInformationKeyName];
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
    // no-op
    NSAssert(NO, @"deprecated cache YUNAccessTokenCacheV3-21 should not be used to cache a token");
}

@end
