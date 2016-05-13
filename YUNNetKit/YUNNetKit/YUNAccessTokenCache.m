//
//  YUNAccessTokenCache.m
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNAccessTokenCache.h"

#import "YUNAccessTokenCacheV3.h"
#import "YUNAccessTokenCacheV3_17.h"
#import "YUNAccessTokenCacheV3_21.h"
#import "YUNAccessTokenCacheV4.h"

static BOOL g_tryDeprecatedCached = YES;

@implementation YUNAccessTokenCache

- (YUNAccessToken *)fetchAccessToken
{
    YUNAccessToken *token = [[[YUNAccessTokenCacheV4 alloc] init] fetchAccessToken];
    if (token || !g_tryDeprecatedCached) {
        return token;
    }
    
    g_tryDeprecatedCached = NO;
    NSArray *oldCacheClasses = [[self class] deprecatedCacheClasses];
    __block YUNAccessToken *oldToken = nil;
    [oldCacheClasses enumerateObjectsUsingBlock:^(Class obj, NSUInteger idx, BOOL *stop) {
        id<YUNAccessTokenCaching> cache = [[obj alloc] init];
        oldToken = [cache fetchAccessToken];
        if (oldToken) {
            *stop = YES;
            [cache clearCache];
        }
    }];
    if (oldToken) {
        [self cacheAccessToken:oldToken];
    }
    return oldToken;
}

- (void)cacheAccessToken:(YUNAccessToken *)token
{
    [[[YUNAccessTokenCacheV4 alloc] init] cacheAccessToken:token];
    if (g_tryDeprecatedCached) {
        g_tryDeprecatedCached = NO;
        NSArray *oldCacheClasses = [[self class] deprecatedCacheClasses];
        [oldCacheClasses enumerateObjectsUsingBlock:^(Class obj, NSUInteger idx, BOOL *stop) {
            id<YUNAccessTokenCaching> cache = [[obj alloc] init];
            [cache clearCache];
        }];
    }
}

- (void)clearCache
{
    [[[YUNAccessTokenCacheV4 alloc] init] clearCache];
}

// used by YUNAccessTokenCacheIntegrationTests
+ (void)resetV3CacheChecks
{
    g_tryDeprecatedCached = YES;
}

+ (NSArray *)deprecatedCacheClasses
{
    return @[
             [YUNAccessTokenCacheV3_17 class],
             [YUNAccessTokenCacheV3_17 class],
             [YUNAccessTokenCacheV3 class],
             ];
}

@end
