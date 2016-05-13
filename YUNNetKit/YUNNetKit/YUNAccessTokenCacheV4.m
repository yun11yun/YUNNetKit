//
//  YUNAccessTokenCacheV4.m
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNAccessTokenCacheV4.h"

#import "YUNDynamicFrameworkLoader.h"
#import "YUNInternalUtility.h"
#import "YUNKeychainStore.h"

static NSString *const kYUNAccessTokenUserDefaultsKey = @"yun11yun.v4.YUNAccessTokenInformationKey";
static NSString *const kYUNAccessTokenUUIDkey = @"tokenUUID";
static NSString *const kYUNAccessTokenEncodedKey = @"tokenEncoded";

@implementation YUNAccessTokenCacheV4
{
    YUNKeychainStore *_keychainStore;
}

- (instancetype)init
{
    if ((self = [super init])) {
        NSString *keyChainServiceIdentifier = [NSString stringWithFormat:@"yun11yun.tokencache.%@", [[NSBundle mainBundle] bundleIdentifier]];
        _keychainStore = [[YUNKeychainStore alloc] initWithService:keyChainServiceIdentifier accessGroup:nil];
    }
    return self;
}


- (YUNAccessToken *)fetchAccessToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults objectForKey:kYUNAccessTokenUserDefaultsKey];
    
    NSDictionary *dict = [_keychainStore dictionarayForKey:kYUNAccessTokenUserDefaultsKey];
    if (![dict[kYUNAccessTokenUUIDkey] isEqualToString:uuid]) {
        // if the uuid doesn't match (including if there is no uuid in defaults which means uninstalled case)
        // clear the keychain and return nil.
        [self clearCache];
        return nil;
    }
    
    id tokenData = dict[kYUNAccessTokenEncodedKey];
    if ([tokenData isKindOfClass:[NSData class]]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
    } else {
        return nil;
    }
}

- (void)cacheAccessToken:(YUNAccessToken *)token
{
    if (!token) {
        [self clearCache];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults objectForKey:kYUNAccessTokenUserDefaultsKey];
    if (!uuid) {
        uuid = [[NSUUID UUID] UUIDString];
        [defaults setObject:uuid forKey:kYUNAccessTokenUserDefaultsKey];
        [defaults synchronize];
    }
    NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
    NSDictionary *dict = @{
                           kYUNAccessTokenUUIDkey : uuid,
                           kYUNAccessTokenEncodedKey : tokenData,
                           };
    
    [_keychainStore setDictionary:dict
                           forKey:kYUNAccessTokenUserDefaultsKey
                    accessibility:[YUNDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

- (void)clearCache
{
    [_keychainStore setDictionary:nil
                           forKey:kYUNAccessTokenUserDefaultsKey
                    accessibility:NULL];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kYUNAccessTokenUserDefaultsKey];
    [defaults synchronize];
}

@end
