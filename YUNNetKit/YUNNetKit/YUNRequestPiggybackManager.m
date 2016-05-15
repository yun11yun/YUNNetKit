//
//  YUNRequestPiggybackManager.m
//  YUNNetKit
//
//  Created by Orange on 5/13/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNRequestPiggybackManager.h"
#import "YUNSettings.h"
#import "YUNRequestMetadata.h"
#import "YUNRequestConnection+Internal.h"
#import "YUNAccessToken.h"
#import "YUNRequest.h"
#import "YUNRequest+Internal.h"
#import "YUNInternalUtility.h"
#import "YUNServerConfigurationManager+Internal.h"

static int const YUNTokenRefreshTresholdSeconds = 24 * 60 * 60; // day
static int const YUNTokenRefreshRetrySeconds = 60 * 60;         // hour

@implementation YUNRequestPiggybackManager

+ (void)addPiggybackRequests:(YUNRequestConnection *)connection
{
    if ([YUNSettings appID].length > 0) {
        BOOL safeForPiggyback = YES;
        if (safeForPiggyback) {
            [[self class] addRefreshPiggybackIfState:connection];
            [[self class] addServerConfigurationPiggyback:connection];
        }
    }
}

+ (void)addRefreshPiggyback:(YUNRequestConnection *)connection permissionHandler:(YUNRequestHandler)permissionHandler
{
    YUNAccessToken *expectedToken = [YUNAccessToken currentAccessToken];
    __block NSMutableSet *permissions = nil;
    __block NSMutableSet *declinedPermissions = nil;
    __block NSString *tokenString = nil;
    __block NSNumber *expirationDateNumber = nil;
    __block int expectingCallbacksCount = 2;
    void (^expectingCallbackComplete)(void) = ^{
        if (--expectingCallbacksCount == 0) {
            YUNAccessToken *currentToken = [YUNAccessToken currentAccessToken];
            NSDate *expirationDate = currentToken.expirationDate;
            if (expirationDateNumber) {
                expirationDate = ([expirationDateNumber doubleValue] > 0 ?
                                  [NSDate dateWithTimeIntervalSince1970:[expirationDateNumber doubleValue]] : [NSDate distantFuture]);
            }
            YUNAccessToken *refreshedToken = [[YUNAccessToken alloc] initWithTokenString:tokenString ?: currentToken.tokenString
                                                                                 permissions:[(permissions ?: currentToken.permissions) allObjects]
                                                                         declinedPermissions:[(declinedPermissions ?: currentToken.declinedPermissions) allObjects]
                                                                                       appID:currentToken.appID
                                                                                      userID:currentToken.userID
                                                                              expirationDate:expirationDate
                                                                                 refreshDate:[NSDate date]];
            if (expectedToken == currentToken) {
                [YUNAccessToken setCurrentAccessToken:refreshedToken];
            }
        }
    };
    YUNRequest *extendRequest = [[YUNRequest alloc] initWithPath:@"oauth/access_token"
                                                      parameters:@{@"grant_type" : @"fb_extend_sso_token",
                                                                                                   @"fields": @""
                                                                                                   }
                                                           flags:YUNRequestFlagDisableErrorRecovery];
    [connection addRequest:extendRequest completionHandler:^(YUNRequestConnection *connection, id result, NSError *error) {
        tokenString = result[@"access_token"];
        expirationDateNumber = result[@"expires_at"];
        expectingCallbackComplete();
    }];
    YUNRequest *permissionsRequest = [[YUNRequest alloc] initWithPath:@"me/permissions" parameters:@{@"fields" : @""} flags:YUNRequestFlagDisableErrorRecovery];
    [connection addRequest:permissionsRequest completionHandler:^(YUNRequestConnection *innerConnection, id result, NSError *error) {
        if (!error) {
            permissions = [NSMutableSet set];
            declinedPermissions = [NSMutableSet set];
            
            [YUNInternalUtility extractPermissionsFromResponse:result
                                            grantedPermissions:permissions
                                           declinedPermissions:declinedPermissions];
        }
        expectingCallbackComplete();
        if (permissionHandler) {
            permissionHandler(innerConnection, result, error);
        }
    }];
}

+ (void)addRefreshPiggybackIfState:(YUNRequestConnection *)connection
{
    // don't piggy back more than once an hour as a cheap way of
    // retrying in cases of errors and preventing duplicate refreshes.
    // obviously this is not foolproof but is simple and sufficient.
    static NSDate *lastRefreshTry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lastRefreshTry = [NSDate distantPast];
    });
    
    NSDate *now = [NSDate date];
    NSDate *tokenRefreshDate = [YUNAccessToken currentAccessToken].refreshDate;
    if (tokenRefreshDate &&
        [now timeIntervalSinceDate:lastRefreshTry] > YUNTokenRefreshRetrySeconds &&
        [now timeIntervalSinceDate:tokenRefreshDate] > YUNTokenRefreshTresholdSeconds) {
        [self addRefreshPiggyback:connection permissionHandler:NULL];
        lastRefreshTry = [NSDate date];
    }
}

+ (void)addServerConfigurationPiggyback:(YUNRequestConnection *)connection
{
    if (![[YUNServerConfigurationManager cachedServerConfiguration] isDefaults]) {
        return;
    }
    NSString *appID = [YUNSettings appID];
    YUNRequest *serverConfigurationRequest = [YUNServerConfigurationManager requestToLoadServerConfiguration:appID];
    [connection addRequest:serverConfigurationRequest completionHandler:^(YUNRequestConnection *connection, id result, NSError *error) {
        [YUNServerConfigurationManager processLoadRequestResponse:result error:error appID:appID];
    }];
}

@end
