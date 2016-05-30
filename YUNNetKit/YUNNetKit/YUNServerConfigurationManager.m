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
    NSString *appID = [YUNSettings appID];
    @synchronized(self) {
        // validate the cached configuration has the correct appID
        if (_serverConfiguration) {
            _serverConfiguration = nil;
            _serverConfigurationError = nil;
            _serverConfigurationErrorTimestamp = nil;
        }
        
        // load the configuration from NSUserDefaults
        if (!_serverConfiguration) {
            // load the defaults
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *defaultsKey = [NSString stringWithFormat:YUN_SERVER_CONFIGURATION_USER_DEFAULTS_KEY, appID];
            NSData *data = [defaults objectForKey:defaultsKey];
            if ([data isKindOfClass:[NSData class]]) {
                // decode the configuration
                YUNServerConfiguration *serverConfiguration = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if ([serverConfiguration isKindOfClass:[YUNServerConfiguration class]]) {
                    // ensure that the configuration points to the current appID
                    _serverConfiguration = serverConfiguration;
                }
            }
        }
        
        if ((_serverConfiguration && [self _serverConfigurationTimestampIsValid:_serverConfiguration.timestamp]) ||
            (_serverConfigurationErrorTimestamp && [self _serverConfigurationTimestampIsValid:_serverConfigurationErrorTimestamp])) {
            // we have a valid server configuration, use that
            loadBlock = [self _wrapperBlockForLoadBlock:completionBlock];
        } else {
            // hold onto the completion block
            [YUNInternalUtility array:_completionBlocks addObject:[completionBlock copy]];
            
            // check if we are already loading
            if (!_loadingServerConfiguration) {
                // load the configuration from the network
                _loadingServerConfiguration = YES;
                YUNRequest *request = [[self class] requestToLoadServerConfiguration:appID];
                
                // start request with specified timeout instead of the default 180s
                YUNRequestConnection *requestConnection = [[YUNRequestConnection alloc] init];
                requestConnection.timeout = kTimeout;
                [requestConnection addRequest:request completionHandler:^(YUNRequestConnection *connection, id result, NSError *error) {
                    [self processLoadRequestResponse:result error:error appID:appID];
                }];
                [requestConnection start];
            }
        }
    }
    
    if (loadBlock != NULL) {
        loadBlock();
    }
}

#pragma mark - Internal Class Methods

+ (void)processLoadRequestResponse:(id)result error:(NSError *)error appID:(NSString *)appID
{
    if (error) {
        [self _didProcessConfigurationFromNetwork:nil appID:appID error:error];
        return;
    }
    
    NSDictionary *resultDictionary = [YUNTypeUtility dictionaryValue:result];
    NSUInteger appEventsFeatures = [YUNTypeUtility unsignedIntegerValue:resultDictionary[YUN_SERVER_CONFIGURATION_APP_EVENTS_FEATURES_FIELD]];
    BOOL advertisingIDEnabled = (appEventsFeatures & YUNServerConfigurationManagerAppEventsFeaturesAdvertisingIDEnabled);
    BOOL implicitPurchaseLoggingEnabled = (appEventsFeatures & YUNServerConfigurationManagerAppEventsFeaturesImplicitPurchaseLoggingEnabled);
    BOOL loginTooltipEnabled = [YUNTypeUtility boolValue:resultDictionary[YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_FIELD]];
    NSString *loginTooltipText = [YUNTypeUtility stringValue:resultDictionary[YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_FIELD]];
    NSString *defaultShareMode = [YUNTypeUtility stringValue:resultDictionary[YUN_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_FIELD]];
    BOOL implicitLoggingEnabled = [YUNTypeUtility boolValue:resultDictionary[YUN_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_FIELD]];
    BOOL systemAuthenticationEnabled = [YUNTypeUtility boolValue:resultDictionary[YUN_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_FIELD]];
    BOOL nativeAuthFlowEnabled =      [YUNTypeUtility boolValue:resultDictionary[YUN_SERVER_CONFIGURATION_NATIVE_PROXY_AUTH_FLOW_ENABLED_FIELD]];
    NSDictionary *dialogConfigurations = [YUNTypeUtility dictionaryValue:resultDictionary[YUN_SERVER_CONFIGURATION_DIALOG_CONFIGS_FIELD]];
    dialogConfigurations = [self _parseDialogConfigurations:dialogConfigurations];
    NSDictionary *dialogFlows = [YUNTypeUtility dictionaryValue:resultDictionary[YUN_SERVER_CONFIGURATION_DIALOG_FLOWS_FIELD]];
    YUNErrorConfiguration *errorConfiguration = [[YUNErrorConfiguration alloc] initWithDictionary:nil];
    [errorConfiguration parseArray:resultDictionary[YUN_SERVER_CONFIGURATION_ERROR_CONFIGURATION_FIELD]];
    YUNServerConfiguration *serverConfiguration = [[YUNServerConfiguration alloc] initWithLoginTooltipEnabled:loginTooltipEnabled
                                                                                   loginTooltipText:loginTooltipText
                                                                                   defaultShareMode:defaultShareMode
                                                                               advertisingIDEnabled:advertisingIDEnabled
                                                                             implicitLoggingEnabled:implicitLoggingEnabled
                                                                     implicitPurchaseLoggingEnabled:implicitPurchaseLoggingEnabled
                                                                        systemAuthenticationEnabled:systemAuthenticationEnabled
                                                                              nativeAuthFlowEnabled:nativeAuthFlowEnabled
                                                                               dialogConfigurations:dialogConfigurations
                                                                                        dialogFlows:dialogFlows
                                                                                          timestamp:[NSDate date]
                                                                                 errorConfiguration:errorConfiguration
                                                                                           defaults:NO];
    [self _didProcessConfigurationFromNetwork:serverConfiguration appID:appID error:nil];
}

+ (YUNRequest *)requestToLoadServerConfiguration:(NSString *)appID
{
    NSOperatingSystemVersion operatingSystemVersion = [YUNInternalUtility operatingSystemVersion];
    NSString *dialogFlowsField = [NSString stringWithFormat:@"%@.os_version(%ti.%ti.%ti)",
                                  YUN_SERVER_CONFIGURATION_DIALOG_FLOWS_FIELD,
                                  operatingSystemVersion.majorVersion,
                                  operatingSystemVersion.minorVersion,
                                  operatingSystemVersion.patchVersion];
    NSArray *fields = @[YUN_SERVER_CONFIGURATION_APP_EVENTS_FEATURES_FIELD,
                        YUN_SERVER_CONFIGURATION_APP_NAME_FIELD,
                        YUN_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_FIELD,
                        YUN_SERVER_CONFIGURATION_DIALOG_CONFIGS_FIELD,
                        dialogFlowsField,
                        YUN_SERVER_CONFIGURATION_ERROR_CONFIGURATION_FIELD,
                        YUN_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_FIELD,
                        YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_FIELD,
                        YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_FIELD,
                        YUN_SERVER_CONFIGURATION_NATIVE_PROXY_AUTH_FLOW_ENABLED_FIELD,
                        YUN_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_FIELD,
                        ];
    NSDictionary *parameters = @{ @"fields": [fields componentsJoinedByString:@","] };
    YUNRequest *request = [[YUNRequest alloc] initWithPath:appID
                                                                   parameters:parameters
                                                                  tokenString:nil
                                                                   HTTPMethod:nil
                                                                        flags:YUNRequestFlagSkipClientToken | YUNRequestFlagDisableErrorRecovery];
    return request;
}

#pragma mark - Helper Class Methods

+ (YUNServerConfiguration *)_defaultServerConfigurationForAppID:(NSString *)appID
{
    // Use a default configuration while we do not have a configuration back from the server. This allows us to set
    // the default values for any of the dialog sets or anything else in a centralized location while we are waiting for
    // the server to respond.
    static YUNServerConfiguration *_defaultServerConfiguration = nil;
    if (NO) {
        // Bypass the native dialog flow for iOS 9+, as it produces a series of additional confirmation dialogs that lead to
        // extra friction that is not desirable.
        NSOperatingSystemVersion iOS9Version = { .majorVersion = 9, .minorVersion = 0, .patchVersion = 0 };
        BOOL useNativeFlow = ![YUNInternalUtility isOSRunTimeVersionAtLeast:iOS9Version];
        // Also enable SFSafariViewController by default.
        NSDictionary *dialogFlows = @{
                                      YUNDialogConfigurationNameDefault: @{
                                              YUNDialogConfigurationFeatureUseNativeFlow: @(useNativeFlow),
                                              YUNDialogConfigurationFeatureUseSafariViewController: @YES,
                                              },
                                      YUNDialogConfigurationNameMessage: @{
                                              YUNDialogConfigurationFeatureUseNativeFlow: @YES,
                                              },
                                      };
        _defaultServerConfiguration = [[YUNServerConfiguration alloc] initWithLoginTooltipEnabled:NO
                                                                     loginTooltipText:nil
                                                                     defaultShareMode:nil
                                                                 advertisingIDEnabled:NO
                                                               implicitLoggingEnabled:NO
                                                       implicitPurchaseLoggingEnabled:NO
                                                          systemAuthenticationEnabled:NO
                                                                nativeAuthFlowEnabled:NO
                                                                 dialogConfigurations:nil
                                                                          dialogFlows:dialogFlows
                                                                            timestamp:nil
                                                                   errorConfiguration:nil
                                                                             defaults:YES];
    }
    return _defaultServerConfiguration;
}

+ (void)_didProcessConfigurationFromNetwork:(YUNServerConfiguration *)serverConfiguration
                                      appID:(NSString *)appID
                                      error:(NSError *)error
{
    NSMutableArray *completionBlocks = [[NSMutableArray alloc] init];
    @synchronized(self) {
        if (error) {
            // Only set the error if we don't have previously fetched app settings.
            // (i.e., if we have app settings and a new call gets an error, we'll
            // ignore the error and surface the last successfully fetched settings).
            if (_serverConfiguration) {
                // We have older app settings but the refresh received an error.
                // Log and ignore the error.
                [YUNLogger singleShotLogEntry:YUNLoggingBehaviorInformational
                                   formatString:@"loadServerConfigurationWithCompletionBlock failed with %@", error];
            } else {
                _serverConfiguration = nil;
            }
            _serverConfigurationError = error;
            _serverConfigurationErrorTimestamp = [NSDate date];
        } else {
            _serverConfiguration = serverConfiguration;
            _serverConfigurationError = nil;
            _serverConfigurationErrorTimestamp = nil;
        }
        
        // update the cached copy in NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *defaultsKey = [NSString stringWithFormat:YUN_SERVER_CONFIGURATION_USER_DEFAULTS_KEY, appID];
        if (serverConfiguration) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:serverConfiguration];
            [defaults setObject:data forKey:defaultsKey];
        }
        
        // wrap the completion blocks
        for (YUNServerConfigurationManagerLoadBlock completionBlock in _completionBlocks) {
            [completionBlocks addObject:[self _wrapperBlockForLoadBlock:completionBlock]];
        }
        [_completionBlocks removeAllObjects];
        _loadingServerConfiguration = NO;
    }
    
    // release the lock before calling out of this class
    for (void (^completionBlock)(void) in completionBlocks) {
        completionBlock();
    }
}

+ (NSDictionary *)_parseDialogConfigurations:(NSDictionary *)dictionary
{
    NSMutableDictionary *dialogConfigurations = [[NSMutableDictionary alloc] init];
    NSArray *dialogConfigurationsArray = [YUNTypeUtility arrayValue:dictionary[@"data"]];
    for (id dialogConfiguration in dialogConfigurationsArray) {
        NSDictionary *dialogConfigurationDictionary = [YUNTypeUtility dictionaryValue:dialogConfiguration];
        if (dialogConfigurationDictionary) {
            NSString *name = [YUNTypeUtility stringValue:dialogConfigurationDictionary[@"name"]];
            if ([name length]) {
                NSURL *URL = [YUNTypeUtility URLValue:dialogConfigurationDictionary[@"url"]];
                NSArray *appVersions = [YUNTypeUtility arrayValue:dialogConfigurationDictionary[@"versions"]];
                dialogConfigurations[name] = [[YUNDialogConfiguration alloc] initWithName:name
                                                                                        URL:URL
                                                                                appVersions:appVersions];
            }
        }
    }
    return dialogConfigurations;
}

+ (BOOL)_serverConfigurationTimestampIsValid:(NSDate *)timestamp
{
    return ([[NSDate date] timeIntervalSinceDate:timestamp] < YUN_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT);
}

+ (void(^)(void))_wrapperBlockForLoadBlock:(YUNServerConfigurationManagerLoadBlock)loadBlock
{
    if (loadBlock == NULL) {
        return NULL;
    }
    
    // create local vars to capture the current values from the ivars to allow this wrapper to be called outside of a lock
    YUNServerConfiguration *serverConfiguration;
    NSError *serverConfigurationError;
    @synchronized(self) {
        serverConfiguration = _serverConfiguration;
        serverConfigurationError = _serverConfigurationError;
    }
    return ^{
        loadBlock(serverConfiguration, serverConfigurationError);
    };
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    return nil;
}

@end
