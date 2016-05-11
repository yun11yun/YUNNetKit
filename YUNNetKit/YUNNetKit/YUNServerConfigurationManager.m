//
//  YUNServerConfigurationManager.m
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNServerConfigurationManager+Internal.h"

#import "YUNRequest+Internal.h"
#import "YUNRequest.h"
#import "YUNInternalUtility.h"
#import "YUNLogger.h"
#import "YUNServerConfiguration+Internal.h"
#import "YUNServerConfiguration.h"
#import "YUNSettings.h"
#import "YUNTypeUtility.h"

#define YUN_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT (60 * 60)

#define YUN_SERVER_CONFIGURATION_USER_DEFAULTS_KEY @"yun11yun:serverConfiguration%@"

#define YUN_SERVER_CONFIGURATION_APP_EVENTS_FEATURES_FIELD @"app_events_feature_bitmask"
#define YUN_SERVER_CONFIGURATION_APP_NAME_FIELD @"name"
#define YUN_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_FIELD @"default_share_mode"
#define YUN_SERVER_CONFIGURATION_DIALOG_CONFIGS_FIELD @"ios_dialog_configs"
#define YUN_SERVER_CONFIGURATION_DIALOG_FLOWS_FIELD @"ios_sdk_dialog_flows"
#define YUN_SERVER_CONFIGURATION_ERROR_CONFIGURATION_FIELD @"ios_sdk_error_categories"
#define YUN_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_FIELD @"supports_implicit_sdk_logging"
#define YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_FIELD @"gdpv4_nux_enabled"
#define YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_FIELD @"gdpv4_nux_content"
#define YUN_SERVER_CONFIGURATION_NATIVE_PROXY_AUTH_FLOW_ENABLED_FIELD @"ios_supports_native_proxy_auth_flow"
#define YUN_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_FIELD @"ios_supports_system_auth"

@implementation YUNServerConfigurationManager

static NSMutableArray *_completionBlocks;
static BOOL _loadingServerConfiguration;
static YUNServerConfiguration *_serverConfiguration;
static NSError *_serverConfigurationError;
static NSDate *_serverConfigurationErrorTimestamp;
static const NSTimeInterval kTimeout = 4.0;

typedef NS_OPTIONS(NSUInteger, YUNServerConfigurationManagerAppEventsFeatures)
{
    YUNServerConfigurationManagerAppEventsFeaturesNone                            = 0,
    YUNServerConfigurationManagerAppEventsFeaturesAdvertisingIDEnabled            = 1 << 0,
    YUNServerConfigurationManagerAppEventsFeaturesImplicitPurchaseLoggingEnabled  = 1 << 1,
};

#pragma mark - Public Class Methods

+ (void)initialize
{
    if (self == [YUNServerConfigurationManager class]) {
        _completionBlocks = [[NSMutableArray alloc] init];
    }
}

+ (YUNServerConfiguration *)cachedServerConfiguration
{
    @synchronized(self) {
        // load the server oniguration if we don't have it already
        [self loadServerConfigurationWithCompletionBlock:NULL];
        
        //use whatever configuration we have or the default
        return _serverConfiguration;
    }
}

+ (void)loadServerConfigurationWithCompletionBlock:(YUNServerConfigurationManagerLoadBlock)completionBlock
{
    void (^loadBlock)(void) = NULL;
    @synchronized(self) {
        
    }
}

@end
