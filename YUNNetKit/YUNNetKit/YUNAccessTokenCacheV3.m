//
//  YUNAccessTokenCacheV3.m
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNAccessTokenCacheV3.h"

#import "YUNAccessToken.h"
#import "YUNSettings.h"
#import "YUNTypeUtility.h"

NSString *const YUNTokenInforamtionUUIDKey = @"com.facebook.sdk:TokenInformationUUIDKey";

#define YUN_TOKEN_INFORMATION_TOKEN_KEY @"com.facebook.sdk:TokenInformationTokenKey"
#define YUN_TOKEN_INFORMATION_EXPIRATION_DATE_KEY @"com.facebook.sdk:TokenInformationExpirationDateKey"
#define YUN_TOKEN_INFORMATION_USER_FBID_KEY @"com.facebook.sdk:TokenInformationUserFBIDKey"
#define YUN_TOKEN_INFORMATION_PERMISSIONS_KEY @"com.facebook.sdk:TokenInformationPermissionsKey"
#define YUN_TOKEN_INFORMATION_DECLINED_PERMISSIONS_KEY @"com.facebook.sdk:TokenInformationDeclinedPermissionsKey"
#define YUN_TOKEN_INFORMATION_APP_ID_KEY @"com.facebook.sdk:TokenInformationAppIDKey"
#define YUN_TOKEN_INFORMATION_REFRESH_DATE_KEY @"com.facebook.sdk:TokenInformationRefreshDateKey"

@implementation YUNAccessTokenCacheV3

- (YUNAccessToken *)fetchAccessToken
{
    // Check NSUserDefaults ( <= v3.16 )
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *tokenDictionary = [defaults objectForKey:[YUNSettings legacyUserDefaultTokenInformationKeyName]];
    return [[self class] accessTokenForV3Dictionary:tokenDictionary];
}

- (void)clearCache
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:[YUNSettings legacyUserDefaultTokenInformationKeyName]];
    [defaults synchronize];
}

- (void)cacheAccessToken:(YUNAccessToken *)token
{
    // no-op.
    NSAssert(NO, @"deprecated cache YUNAccessTokenCacheV3 should not be used to cache a token");
}

+ (YUNAccessToken *)accessTokenForV3Dictionary:(NSDictionary *)dictionary
{
    NSString *tokenString = [YUNTypeUtility stringValue:dictionary[YUN_TOKEN_INFORMATION_TOKEN_KEY]];
    if (tokenString.length > 0) {
        NSDate *expirationDate = dictionary[YUN_TOKEN_INFORMATION_EXPIRATION_DATE_KEY];
        // Note we default to valid in cases where expiration date is missing.
        BOOL isExpired = ([expirationDate compare:[NSDate date]] == NSOrderedAscending);
        if (isExpired) {
            return nil;
        }
        return [[YUNAccessToken alloc] initWithTokenString:tokenString
                                               permissions:dictionary[YUN_TOKEN_INFORMATION_PERMISSIONS_KEY]
                                       declinedPermissions:dictionary[YUN_TOKEN_INFORMATION_DECLINED_PERMISSIONS_KEY]
                                                     appID:dictionary[YUN_TOKEN_INFORMATION_APP_ID_KEY]
                                                    userID:dictionary[YUN_TOKEN_INFORMATION_USER_FBID_KEY]
                                            expirationDate:expirationDate
                                               refreshDate:dictionary[YUN_TOKEN_INFORMATION_REFRESH_DATE_KEY]];
    }
    return nil;
}

@end
