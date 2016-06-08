//
//  YUNAccessToken.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNAccessToken.h"

#import "YUNRequestPiggybackManager.h"
#import "YUNInternalUtility.h"
#import "YUNMath.h"
#import "YUNSettings+Internal.h"

NSString *const YUNAccessTokenDidChangeNotification = @"com.yun11yun.YUNAccessTokenDidChangeNotification";
NSString *const YUNAccessTokenDidChangeUserID = @"FBSDKAccessTokenDidChangeUserID";
NSString *const YUNAccessTokenChangeNewKey = @"FBSDKAccessToken";
NSString *const YUNAccessTokenChangeOldKey = @"FBSDKAccessTokenOld";

static YUNAccessToken *g_currentAccessToken;

#define YUN_ACCESSTOKEN_TOKENSTRING_KEY @"tokenString"
#define YUN_ACCESSTOKEN_PERMISSIONS_KEY @"permissions"
#define YUN_ACCESSTOKEN_DECLINEDPERMISSIONS_KEY @"declinedPermissions"
#define YUN_ACCESSTOKEN_APPID_KEY @"appID"
#define YUN_ACCESSTOKEN_USERID_KEY @"userID"
#define YUN_ACCESSTOKEN_REFRESHDATE_KEY @"refreshDate"
#define YUN_ACCESSTOKEN_EXPIRATIONDATE_KEY @"expirationDate"

@implementation YUNAccessToken

- (instancetype)init NS_UNAVAILABLE
{
    assert(0);
}

- (instancetype)initWithTokenString:(NSString *)tokenString
                        permissions:(NSArray *)permissions
                declinedPermissions:(NSArray *)declinedPermissions
                              appID:(NSString *)appID
                             userID:(NSString *)userID
                     expirationDate:(NSDate *)expirationDate
                        refreshDate:(NSDate *)refreshDate
{
    if ((self = [super init])) {
        _tokenString = [tokenString copy];
        _permissions = [NSSet setWithArray:permissions];
        _declinedPermissions = [NSSet setWithArray:declinedPermissions];
        _appID = [appID copy];
        _userID = [userID copy];
        _expirationDate = [expirationDate copy] ?: [NSDate distantFuture];
        _refreshDate = [refreshDate copy] ?: [NSDate date];
    }
    return self;
}

- (BOOL)hasGranted:(NSString *)permission
{
    return [self.permissions containsObject:permission];
}

+ (YUNAccessToken *)currentAccessToken
{
    return g_currentAccessToken;
}

+ (void)setCurrentAccessToken:(YUNAccessToken *)token
{
    if (token != g_currentAccessToken) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [YUNInternalUtility dictionary:userInfo setObject:token forKey:YUNAccessTokenChangeNewKey];
        [YUNInternalUtility dictionary:userInfo setObject:g_currentAccessToken forKey:YUNAccessTokenChangeOldKey];
        if (![g_currentAccessToken.userID isEqualToString:token.userID]) {
            userInfo[YUNAccessTokenDidChangeUserID] = @YES;
        }
        
        g_currentAccessToken = token;
        
        if (token == nil) {
        }
        
        
        [[YUNSettings accessTokenCache] cacheAccessToken:token];
        [[NSNotificationCenter defaultCenter] postNotificationName:YUNAccessTokenDidChangeNotification object:[self class] userInfo:userInfo];
        
    }
}

#pragma mark - Equality

- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        [self.tokenString hash],
        [self.permissions hash],
        [self.declinedPermissions hash],
        [self.appID hash],
        [self.userID hash],
        [self.refreshDate hash],
        [self.expirationDate hash]
    };
    return [YUNMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
    
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[YUNAccessToken class]]) {
        return NO;
    }
    return [self isEqualToAccessToken:(YUNAccessToken *)object];
}

- (BOOL)isEqualToAccessToken:(YUNAccessToken *)token
{
    return (token &&
            [YUNInternalUtility object:self.tokenString isEqualToObject:token.tokenString] &&
            [YUNInternalUtility object:self.permissions isEqualToObject:token.permissions] &&
            [YUNInternalUtility object:self.declinedPermissions isEqualToObject:token.declinedPermissions] &&
            [YUNInternalUtility object:self.appID isEqualToObject:token.appID] &&
            [YUNInternalUtility object:self.userID isEqualToObject:token.userID] &&
            [YUNInternalUtility object:self.refreshDate isEqualToObject:token.refreshDate] &&
            [YUNInternalUtility object:self.expirationDate isEqualToObject:token.expirationDate]);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    // We're immutable
    return self;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSString *appID = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_ACCESSTOKEN_APPID_KEY];
    NSSet *declinedPermissions = [decoder decodeObjectOfClass:[NSSet class] forKey:YUN_ACCESSTOKEN_DECLINEDPERMISSIONS_KEY];
    NSSet *permissions = [decoder decodeObjectOfClass:[NSSet class] forKey:YUN_ACCESSTOKEN_PERMISSIONS_KEY];
    NSString *tokenString = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_ACCESSTOKEN_TOKENSTRING_KEY];
    NSString *userID = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_ACCESSTOKEN_USERID_KEY];
    NSDate *refreshDate = [decoder decodeObjectOfClass:[NSDate class] forKey:YUN_ACCESSTOKEN_REFRESHDATE_KEY];
    NSDate *expirationDate = [decoder decodeObjectOfClass:[NSDate class] forKey:YUN_ACCESSTOKEN_EXPIRATIONDATE_KEY];
    
    return [self initWithTokenString:tokenString
                         permissions:[permissions allObjects]
                 declinedPermissions:[declinedPermissions allObjects]
                               appID:appID
                              userID:userID
                      expirationDate:expirationDate
                         refreshDate:refreshDate];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.appID forKey:YUN_ACCESSTOKEN_APPID_KEY];
    [encoder encodeObject:self.declinedPermissions forKey:YUN_ACCESSTOKEN_DECLINEDPERMISSIONS_KEY];
    [encoder encodeObject:self.permissions forKey:YUN_ACCESSTOKEN_PERMISSIONS_KEY];
    [encoder encodeObject:self.tokenString forKey:YUN_ACCESSTOKEN_TOKENSTRING_KEY];
    [encoder encodeObject:self.userID forKey:YUN_ACCESSTOKEN_USERID_KEY];
    [encoder encodeObject:self.expirationDate forKey:YUN_ACCESSTOKEN_EXPIRATIONDATE_KEY];
    [encoder encodeObject:self.refreshDate forKey:YUN_ACCESSTOKEN_REFRESHDATE_KEY];
}

@end
