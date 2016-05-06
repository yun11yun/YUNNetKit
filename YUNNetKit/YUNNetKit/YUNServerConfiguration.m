//
//  YUNServerConfiguration.m
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNServerConfiguration.h"
#import "YUNServerConfiguration+Internal.h"


#define YUN_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY @"advertisingIDEnabled"
#define YUN_SERVER_CONFIGURATION_APP_ID_KEY @"appID"
#define YUN_SERVER_CONFIGURATION_APP_NAME_KEY @"appName"
#define YUN_SERVER_CONFIGURATION_DIALOG_CONFIGS_KEY @"dialogConfigs"
#define YUN_SERVER_CONFIGURATION_DIALOG_FLOWS_KEY @"dialogFlows"
#define YUN_SERVER_CONFIGURATION_ERROR_CONFIGS_KEY @"errorConfigs"
#define YUN_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY @"implicitLoggingEnabled"
#define YUN_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_KEY @"defaultShareMode"
#define YUN_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY @"implicitPurchaseLoggingEnabled"
#define YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY @"loginTooltipEnabled"
#define YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY @"loginTooltipText"
#define YUN_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_KEY @"systemAuthenticationEnabled"
#define YUN_SERVER_CONFIGURATION_NATIVE_AUTH_FLOW_ENABLED_KEY @"nativeAuthFlowEnabled"
#define YUN_SERVER_CONFIGURATION_TIMESTAMP_KEY @"timestamp"

NSString *const YUNDialogConfigurationNameLogin = @"login";

NSString *const YUNDialogConfigurationNameAppInvite = @"app_invite";
NSString *const YUNDialogConfigurationNameGameRequest = @"game_request";
NSString *const YUNDialogConfigurationNameGroup = @"group";
NSString *const YUNDialogConfigurationNameLike = @"like";
NSString *const YUNDialogConfigurationNameMessage = @"message";
NSString *const YUNDialogConfigurationNameShare = @"share";

NSString *const YUNDialogConfigurationNameDefault = @"default";
NSString *const YUNDialogConfigurationNameSharing = @"sharing";

NSString *const YUNDialogConfigurationFeatureUseNativeFlow = @"use_native_flow";
NSString *const YUNDialogConfigurationFeatureUseSafariViewController = @"use_safari_vc";

@implementation YUNServerConfiguration
{
    NSDictionary *_dialogConfigurations;
    NSDictionary *_dialogFlows;
}

#pragma mark - Object Lifecycle

- (instancetype)init NS_UNAVAILABLE
{
    assert(0);
}

- (instancetype)initWithLoginTooltipEnabled:(BOOL)loginTooltipEnabled
                           loginTooltipText:(NSString *)loginTooltipText
                           defaultShareMode:(NSString *)defaultShareMode
                       advertisingIDEnabled:(BOOL)advertisingIDEnabled
                     implicitLoggingEnabled:(BOOL)implicitLoggingEnabled
             implicitPurchaseLoggingEnabled:(BOOL)implicitPurchaseLoggingEnabled
                systemAuthenticationEnabled:(BOOL)systemAuthenticationEnabled
                      nativeAuthFlowEnabled:(BOOL)nativeAuthFlowEnabled
                       dialogConfigurations:(NSDictionary *)dialogConfigurations
                                dialogFlows:(NSDictionary *)dialogFlows
                                  timestamp:(NSDate *)timestamp
                         errorConfiguration:(YUNErrorConfiguration *)errorConfiguration
                                   defaults:(BOOL)defaults {
    if ((self = [super init])) {
        _loginTooltipEnabled = loginTooltipEnabled;
        _loginTooltipText = [loginTooltipText copy];
        _defaultShareMode = defaultShareMode;
        _advertisingIDEnabled = advertisingIDEnabled;
        _implicitLoggingEnabled = implicitLoggingEnabled;
        _implicitPurchaseLoggingEnabled = implicitPurchaseLoggingEnabled;
        _systemAuthenticationEnabled = systemAuthenticationEnabled;
        _nativeAuthFlowEnabled = nativeAuthFlowEnabled;
        _dialogConfigurations = [dialogConfigurations copy];
        _dialogFlows = [_dialogFlows copy];
        _timestamp = [timestamp copy];
        _errorConfiguration = [errorConfiguration copy];
        _defaults = defaults;
    }
    return self;
}

#pragma mark - Public Methods

- (YUNDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName
{
    return _dialogConfigurations[dialogName];
}

- (BOOL)useNativeDialogForDialogName:(NSString *)dialogName
{
    return [self p_useFeatureWithKey:YUNDialogConfigurationFeatureUseNativeFlow dialogName:dialogName];
}

- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName
{
    return [self p_useFeatureWithKey:YUNDialogConfigurationFeatureUseSafariViewController dialogName:dialogName];
}


#pragma mark - Helper Methods

- (BOOL)p_useFeatureWithKey:(NSString *)key dialogName:(NSString *)dialogName
{
    if ([dialogName isEqualToString:YUNDialogConfigurationNameLogin]) {
        return [(NSNumber *)(_dialogFlows[dialogName][key] ?: _dialogFlows[YUNDialogConfigurationNameDefault][key]) boolValue];
    } else {
        return [(NSNumber *)(_dialogFlows[dialogName][key] ?: _dialogFlows[YUNDialogConfigurationNameSharing][key] ?: _dialogFlows[YUNDialogConfigurationNameDefault][key]) boolValue];
    }
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    BOOL loginTooltipEnabled = [decoder decodeBoolForKey:YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY];
    NSString *loginTooltipText = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY];
    NSString *defaultShareMode = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_KEY];
    BOOL advertisingIDEnabled = [decoder decodeBoolForKey:YUN_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY];
    BOOL implicitLoggingEnabled = [decoder decodeBoolForKey:YUN_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY];
    BOOL implicitPurchaseLoggingEnabled = [decoder decodeBoolForKey:YUN_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY];
    BOOL systemAuthenticationEnabled = [decoder decodeBoolForKey:YUN_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_KEY];
    BOOL nativeAuthFlowEnabled = [decoder decodeBoolForKey:YUN_SERVER_CONFIGURATION_NATIVE_AUTH_FLOW_ENABLED_KEY];
    NSDate *timestamp = [decoder decodeObjectOfClass:[NSDate class] forKey:YUN_SERVER_CONFIGURATION_TIMESTAMP_KEY];
    NSSet *dialogConfigurationsClasses = [[NSSet alloc] initWithObjects:
                                          [NSDictionary class],
                                          [YUNDialogConfiguration class],
                                          nil];
    NSDictionary *dialogConfigurations = [decoder decodeObjectOfClasses:dialogConfigurationsClasses
                                                                 forKey:YUN_SERVER_CONFIGURATION_DIALOG_CONFIGS_KEY];
    NSSet *dialogFlowsClasses = [[NSSet alloc] initWithObjects:
                                 [NSDictionary class],
                                 [NSString class],
                                 [NSNumber class],
                                 nil];
    NSDictionary *dialogFlows = [decoder decodeObjectOfClasses:dialogFlowsClasses
                                                        forKey:YUN_SERVER_CONFIGURATION_DIALOG_FLOWS_KEY];
    YUNErrorConfiguration *errorConfiguration = [decoder decodeObjectOfClass:[YUNErrorConfiguration class] forKey:YUN_SERVER_CONFIGURATION_ERROR_CONFIGS_KEY];
    return [self initWithLoginTooltipEnabled:loginTooltipEnabled
                            loginTooltipText:loginTooltipText
                            defaultShareMode:defaultShareMode
                        advertisingIDEnabled:advertisingIDEnabled
                      implicitLoggingEnabled:implicitLoggingEnabled
              implicitPurchaseLoggingEnabled:implicitPurchaseLoggingEnabled
                 systemAuthenticationEnabled:systemAuthenticationEnabled
                       nativeAuthFlowEnabled:nativeAuthFlowEnabled
                        dialogConfigurations:dialogConfigurations
                                 dialogFlows:dialogFlows
                                   timestamp:timestamp
                          errorConfiguration:errorConfiguration
                                    defaults:NO];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeBool:_advertisingIDEnabled forKey:YUN_SERVER_CONFIGURATION_ADVERTISING_ID_ENABLED_KEY];
    [encoder encodeObject:_defaultShareMode forKey:YUN_SERVER_CONFIGURATION_DEFAULT_SHARE_MODE_KEY];
    [encoder encodeObject:_dialogConfigurations forKey:YUN_SERVER_CONFIGURATION_DIALOG_CONFIGS_KEY];
    [encoder encodeObject:_dialogFlows forKey:YUN_SERVER_CONFIGURATION_DIALOG_FLOWS_KEY];
    [encoder encodeObject:_errorConfiguration forKey:YUN_SERVER_CONFIGURATION_ERROR_CONFIGS_KEY];
    [encoder encodeBool:_implicitLoggingEnabled forKey:YUN_SERVER_CONFIGURATION_IMPLICIT_LOGGING_ENABLED_KEY];
    [encoder encodeBool:_implicitPurchaseLoggingEnabled forKey:YUN_SERVER_CONFIGURATION_IMPLICIT_PURCHASE_LOGGING_ENABLED_KEY];
    [encoder encodeBool:_loginTooltipEnabled forKey:YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_ENABLED_KEY];
    [encoder encodeObject:_loginTooltipText forKey:YUN_SERVER_CONFIGURATION_LOGIN_TOOLTIP_TEXT_KEY];
    [encoder encodeBool:_nativeAuthFlowEnabled forKey:YUN_SERVER_CONFIGURATION_NATIVE_AUTH_FLOW_ENABLED_KEY];
    [encoder encodeBool:_systemAuthenticationEnabled forKey:YUN_SERVER_CONFIGURATION_SYSTEM_AUTHENTICATION_ENABLED_KEY];
    [encoder encodeObject:_timestamp forKey:YUN_SERVER_CONFIGURATION_TIMESTAMP_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
