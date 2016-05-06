//
//  YUNErrorConfiguration.m
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNErrorConfiguration.h"

#import "YUNErrorRecoveryConfiguration.h"
#import "YUNInternalUtility.h"
#import "YUNSettings.h"
#import "YUNRequest.h"

static NSString *const kErrorCategoryOther = @"other";
static NSString *const kErrorCategoryTransient = @"transient";
static NSString *const kErrorCategoryLogin = @"login";

#define YUNERRORCONFIGURATION_DICTIONARY_KEY @"configurationDictionary"

@implementation YUNErrorConfiguration
{
    NSMutableDictionary *_configurationDictionary;
}

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithDictionary:);
    return [self initWithDictionary:nil];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [super init])) {
        if (dictionary) {
            _configurationDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
        } else {
            _configurationDictionary = [NSMutableDictionary dictionary];
            NSString *localizeOK = NSLocalizedStringWithDefaultValue(@"ErrorRecovery.OK", @"FacebookSDK", [YUNInternalUtility bundleForStrings], @"OK", @"The title of the label to start attempting error recovery");
            NSString *localizedCancel =
            NSLocalizedStringWithDefaultValue(@"ErrorRecovery.Cancel", @"FacebookSDK", [YUNInternalUtility bundleForStrings],
                                              @"Cancel",
                                              @"The title of the label to decline attempting error recovery");
            NSString *localizedTransientSuggestion =
            NSLocalizedStringWithDefaultValue(@"ErrorRecovery.Transient.Suggestion", @"FacebookSDK", [YUNInternalUtility bundleForStrings],
                                              @"The server is temporarily busy, please try again.",
                                              @"The fallback message to display to retry transient errors");
            NSString *localizedLoginRecoverableSuggestion =
            NSLocalizedStringWithDefaultValue(@"ErrorRecovery.Login.Suggestion", @"FacebookSDK", [YUNInternalUtility bundleForStrings],
                                              @"Please log into this app again to reconnect your Facebook account.",
                                              @"The fallback message to display to recover invalidated tokens");
            NSArray *fallbackArray = @[
                                       @{ @"name" : @"login",
                                          @"items" : @[ @{ @"code" : @102 },
                                                        @{ @"code" : @190 } ],
                                          @"recovery_message" : localizedLoginRecoverableSuggestion,
                                          @"recovery_options" : @[ localizeOK, localizedCancel]
                                          },
                                       @{ @"name" : @"transient",
                                          @"items" : @[ @{ @"code" : @1 },
                                                        @{ @"code" : @2 },
                                                        @{ @"code" : @4 },
                                                        @{ @"code" : @9 },
                                                        @{ @"code" : @17 },
                                                        @{ @"code" : @341 } ],
                                          @"recovery_message" : localizedTransientSuggestion,
                                          @"recovery_options" : @[ localizeOK]
                                          },
                                       ];
            [self parseArray:fallbackArray];
        }
    }
    return self;
}

- (YUNErrorRecoveryConfiguration *)recoveryConfigurationForCode:(NSString *)code subcode:(NSString *)subcode request:(YUNRequest *)request
{
    code = code ?: @"*";
    subcode = subcode ?: @"*";
    YUNErrorRecoveryConfiguration *configuration = (_configurationDictionary[code][subcode] ?: _configurationDictionary[code][@"*"] ?: _configurationDictionary[@"*"][subcode] ?: _configurationDictionary[@"*"][@"*"]);
    if (configuration.errorCategory == YUNRequestErrorCategoryRecoverable &&
        [YUNSettings clientToken] &&
        [request.parameters[@"access_token"] hasSuffix:[YUNSettings clientToken]]) {
        // do not attempt to recover client tokens.
        return nil;
    }
    return configuration;
}

- (void)parseArray:(NSArray *)array
{
    for (NSDictionary *dictionary in array) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            YUNRequestErrorCategory category;
            NSString *action = dictionary[@"name"];
            if ([action isEqualToString:kErrorCategoryOther]) {
                category = YUNRequestErrorCategoryOther;
            } else if ([action isEqualToString:kErrorCategoryTransient]) {
                category = YUNRequestErrorCategoryTransient;
            } else {
                category = YUNRequestErrorCategoryRecoverable;
            }
            NSString *suggestion = dictionary[@"recovery_message"];
            NSArray *options = dictionary[@"recovery_options"];
            for (NSDictionary *codeSubcodesDictionary in dictionary[@"items"]) {
                NSString *code = [codeSubcodesDictionary[@"code"] stringValue];
                
                NSMutableDictionary *currentSubcodes = _configurationDictionary[code];
                if (!currentSubcodes) {
                    currentSubcodes = [NSMutableDictionary dictionary];
                    _configurationDictionary[code] = currentSubcodes;
                }
                
                NSArray *subcodes = codeSubcodesDictionary[@"subcodes"];
                if (subcodes.count > 0) {
                    for (NSNumber *subcodeNumber in subcodes) {
                        currentSubcodes[[subcodeNumber stringValue]] = [[YUNErrorRecoveryConfiguration alloc] initWithRecoveryDescription:suggestion optionDescriptions:options category:category recoveryActionName:action];
                    }
                } else {
                    currentSubcodes[@"*"] = [[YUNErrorRecoveryConfiguration alloc]
                                             initWithRecoveryDescription:suggestion
                                             optionDescriptions:options
                                             category:category
                                             recoveryActionName:action];
                }
            }
        }];
    }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSDictionary *configurationDictionary = [decoder decodeObjectOfClass:[NSDictionary class] forKey:YUNERRORCONFIGURATION_DICTIONARY_KEY];
    return [self initWithDictionary:configurationDictionary];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_configurationDictionary forKey:YUNERRORCONFIGURATION_DICTIONARY_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
