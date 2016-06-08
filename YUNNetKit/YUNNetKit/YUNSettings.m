//
//  YUNSettings.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/27.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNSettings+Internal.h"

#define YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(TYPE, PLIST_KEY, GETTER, SETTER, DEFAULT_VALUE) \
static TYPE *g_##PLIST_KEY = nil; \
+ (TYPE *)GETTER \
{ \
   if (!g_##PLIST_KEY) { \
       g_##PLIST_KEY = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@#PLIST_KEY] copy] ?: DEFAULT_VALUE; \
    } \
    return g_##PLIST_KEY; \
} \
+ (void)SETTER:(TYPE *)value { \
    g_##PLIST_KEY = [value copy]; \
}

NSString *const YUNLoggingBehaviorAccessTokens = @"include_access_token";
NSString *const YUNLoggingBehaviorPerformanceCharateristics = @"perf_characteristics";
NSString *const YUNLoggingBehaviorAppEvents = @"app_events";
NSString *const YUNLoggingBehaviorInformational = @"informational";
NSString *const YUNLoggingBehaviorCacheErrors = @"cache_errors";
NSString *const YUNLoggingBehaviorUIControlErrors = @"ui_control_errors";
NSString *const YUNLoggingBehaviorGraphAPIDebugWarning = @"graph_api_warning";
NSString *const YUNLoggingBehaviorGraphAPIDebugInfo = @"graph_api_debug_info";
NSString *const YUNLoggingBehaviorNetworkRequests = @"network_requests";
NSString *const YUNLoggingBehaviorDeveloperErrors = @"developer_errors";

static YUNAccessTokenCache *g_tokenCache;
static NSMutableSet *g_loggingBehavior;
static NSString *g_legacyUserDefaultTokenInformationKeyName = @"YUNAccessTokenInformationKey";
static NSString *const YUNSettingsLimitEventAndDataUsage = @"com.yun11yun.sdk:YUNSettingsLimitEventAdnDataUsage";
static BOOL g_disableErrorRecovery;
static NSString *g_userAgentSuffix;

@implementation YUNSettings

+ (void)initialize
{
    if (self == [YUNSettings class]) {
        g_tokenCache = [[YUNAccessTokenCache alloc] init];
    }
}

#pragma mark - Plist Configuration Settings

YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookAppID, appID, setAppID, nil);
YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookUrlSchemeSuffix, appURLSchemeSuffix, setAppURLSchemeSuffix, nil);
YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookClientToken, clientToken, setClientToken, nil);
YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookDisplayName, displayName, setDisplayName, nil);
YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSString, FacebookDomainPart, facebookDomainPart, setFacebookDomainPart, nil);
YUNSETTINGS_PLIST_CONFIGURATION_SETTING_IMPL(NSNumber, FacebookJpegCompressionQuality, _JPEGCompressionQualityNumber, _setJPEGCompressionQualityNumber, @(0.9));

+ (void)setGraphErrorRecoveryDisabled:(BOOL)disableGraphErrorRecovery
{
    g_disableErrorRecovery = disableGraphErrorRecovery;
}

+ (BOOL)isGraphErrorRecoveryDisabled
{
    return g_disableErrorRecovery;
}

+ (CGFloat)JPEGCompressionQuality
{
    return [[self _JPEGCompressionQualityNumber] floatValue];
}

+ (void)setJPEGCompressionQuality:(CGFloat)JPEGCompressionQuality
{
    [self _setJPEGCompressionQualityNumber:@(JPEGCompressionQuality)];
}

+ (BOOL)limitEventAndDataUsage
{
    NSNumber *storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:YUNSettingsLimitEventAndDataUsage];
    if (storedValue == nil) {
        return NO;
    }
    return storedValue.boolValue;
}

+ (void)setLimitEventAndDataUsage:(BOOL)limitEventAndDataUsage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(limitEventAndDataUsage) forKey:YUNSettingsLimitEventAndDataUsage];
    [defaults synchronize];
}

+ (NSSet *)loggingBehavior
{
    if (!g_loggingBehavior) {
        NSArray *bundleLoggingBehaviors = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FaceboolLoggingBehavior"];
        if (bundleLoggingBehaviors) {
            g_loggingBehavior = [[NSMutableSet alloc] initWithArray:bundleLoggingBehaviors];
        } else {
            // Establish set of default enabled logging behaviors. You can completely disable logging by
            // specifying an empty array for YUNLoggingBehavior in you Info.plist.
            g_loggingBehavior = [[NSMutableSet alloc] initWithObjects:YUNLoggingBehaviorDeveloperErrors, nil];
        }
    }
    return [g_loggingBehavior copy];
}

+ (void)setLoggingBehavior:(NSSet *)loggingBehavior
{
    if (![g_loggingBehavior isEqualToSet:loggingBehavior]) {
        g_loggingBehavior = [loggingBehavior mutableCopy];
        
        [self updateGraphAPIDebugBehavior];
    }
}

+ (void)enableLoggingBehavior:(NSString *)loggingBehavior
{
    if (!g_loggingBehavior) {
        [self loggingBehavior];
    }
    [g_loggingBehavior addObject:loggingBehavior];
    [self updateGraphAPIDebugBehavior];
}

+ (void)disableLoggingBehavior:(NSString *)loggingBehavior
{
    if (!g_loggingBehavior) {
        [self loggingBehavior];
    }
    [g_loggingBehavior removeObject:loggingBehavior];
    [self updateGraphAPIDebugBehavior];
}

+ (void)setLegacyUserDefaultTokenInformationKeyName:(NSString *)tokenInformationKeyName
{
    if (![g_legacyUserDefaultTokenInformationKeyName isEqualToString:tokenInformationKeyName]) {
        g_legacyUserDefaultTokenInformationKeyName = tokenInformationKeyName;
    }
}

+ (NSString *)legacyUserDefaultTokenInformationKeyName
{
    return g_legacyUserDefaultTokenInformationKeyName;
}

#pragma mark - Readonly Configuration Settings

+ (NSString *)sdkVersion
{
    return @"";
}

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

#pragma mark - Internal

+ (YUNAccessTokenCache *)accessTokenCache
{
    return g_tokenCache;
}

- (void)setAccessTokenCache:(YUNAccessTokenCache *)cache
{
    if (g_tokenCache != cache) {
        g_tokenCache = cache;
    }
}

+ (NSString *)userAgentSuffix
{
    return g_userAgentSuffix;
}

+ (void)setUserAgentSuffix:(NSString *)suffix
{
    if (![g_userAgentSuffix isEqualToString:suffix]) {
        g_userAgentSuffix = suffix;
    }
}

#pragma mark - Internal - Graph API Debug

+ (void)updateGraphAPIDebugBehavior
{
    // Enable Warnings everytime Info is enabled
    if ([g_loggingBehavior containsObject:YUNLoggingBehaviorGraphAPIDebugInfo] &&
        ![g_loggingBehavior containsObject:YUNLoggingBehaviorGraphAPIDebugWarning]) {
        [g_loggingBehavior addObject:YUNLoggingBehaviorGraphAPIDebugWarning];
    }
}

+ (NSString *)graphAPIDebugParamValue
{
    if ([[self loggingBehavior] containsObject:YUNLoggingBehaviorGraphAPIDebugInfo]) {
        return @"info";
    } else if ([[self loggingBehavior] containsObject:YUNLoggingBehaviorGraphAPIDebugWarning]) {
        return @"warning";
    }
    return nil;
}

@end
