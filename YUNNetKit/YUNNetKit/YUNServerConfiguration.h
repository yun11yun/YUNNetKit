//
//  YUNServerConfiguration.h
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNDialogConfiguration.h"
#import "YUNErrorConfiguration.h"

extern NSString *const YUNDialogConfigurationNameLogin;

extern NSString *const YUNDialogConfigurationNameAppInvite;
extern NSString *const YUNDialogConfigurationNameGameRequest;
extern NSString *const YUNDialogConfigurationNameGroup;
extern NSString *const YUNDialogConfigurationNameLike;
extern NSString *const YUNDialogConfigurationNameMessage;
extern NSString *const YUNDialogConfigurationNameShare;

@interface YUNServerConfiguration : NSObject<NSCopying, NSSecureCoding>

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
                                   defaults:(BOOL)defaults
NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly, getter=isAdvertisingIDEnabled) BOOL advertisingIDEnabled;
@property (nonatomic, assign, readonly, getter=isDefaults) BOOL defaults;
@property (nonatomic, copy, readonly) NSString *defaultShareMode;
@property (nonatomic, strong, readonly) YUNErrorConfiguration *errorConfiguration;
@property (nonatomic, assign, readonly, getter=isImplicitLoggingSupported) BOOL implicitLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isImplicitPurchaseLoggingSupported) BOOL implicitPurchaseLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isLoginTooltipEnabled) BOOL loginTooltipEnabled;
@property (nonatomic, assign, readonly, getter=isNativeAuthFlowEnabled) BOOL nativeAuthFlowEnabled;
@property (nonatomic, assign, readonly, getter=isSystemAuthenticationEnabled) BOOL systemAuthenticationEnabled;
@property (nonatomic, copy, readonly) NSString *loginTooltipText;
@property (nonatomic, copy, readonly) NSDate *timestamp;

- (YUNDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName;
- (BOOL)useNativeDialogForDialogName:(NSString *)dialogName;
- (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName;

@end
