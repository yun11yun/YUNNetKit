//
//  YUNErrorRecoveryConfiguration.m
//  YUNNetKit
//
//  Created by Orange on 5/5/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNErrorRecoveryConfiguration.h"

#define YUN_ERROR_RECOVERY_CONFIGURATION_DESCRIPTION_KEY @"description"
#define YUN_ERROR_RECOVERY_CONFIGURATION_OPTIONS_KEY @"options"
#define YUN_ERROR_RECOVERY_CONFIGURATION_CATEGORY_KEY @"category"
#define YUN_ERROR_RECOVERY_CONFIGURATION_ACTION_KEY @"action"

@implementation YUNErrorRecoveryConfiguration

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithRecoveryDescription:optionDescriptions:category:recoveryActionName:);
    return [self initWithRecoveryDescription:nil
                          optionDescriptions:nil
                                    category:0
                          recoveryActionName:nil];
}

- (instancetype)initWithRecoveryDescription:(NSString *)description
                         optionDescriptions:(NSArray *)optionDescriptions
                                   category:(YUNRequestErrorCategory)category
                         recoveryActionName:(NSString *)recoveryActionName {
    if ((self = [super init])) {
        _localizedRecoveryDescription = [description copy];
        _localizedRecoveryOptionDescriptions = [optionDescriptions copy];
        _errorCategory = category;
        _recoveryActionName = [recoveryActionName copy];
    }
    return self;
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSString *description = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_ERROR_RECOVERY_CONFIGURATION_DESCRIPTION_KEY];
    NSArray *options = [decoder decodeObjectOfClass:[NSArray class] forKey:YUN_ERROR_RECOVERY_CONFIGURATION_OPTIONS_KEY
                         ];
    NSNumber *category = [decoder decodeObjectOfClass:[NSNumber class] forKey:YUN_ERROR_RECOVERY_CONFIGURATION_CATEGORY_KEY];
    NSString *action = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_ERROR_RECOVERY_CONFIGURATION_ACTION_KEY];
    
    return [self initWithRecoveryDescription:description
                          optionDescriptions:options
                                    category:[category unsignedIntegerValue]
                          recoveryActionName:action];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_localizedRecoveryDescription forKey:YUN_ERROR_RECOVERY_CONFIGURATION_DESCRIPTION_KEY];
    [encoder encodeObject:_localizedRecoveryOptionDescriptions forKey:YUN_ERROR_RECOVERY_CONFIGURATION_OPTIONS_KEY];
    [encoder encodeObject:@(_errorCategory) forKey:YUN_ERROR_RECOVERY_CONFIGURATION_CATEGORY_KEY];
    [encoder encodeObject:_recoveryActionName forKey:YUN_ERROR_RECOVERY_CONFIGURATION_ACTION_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
