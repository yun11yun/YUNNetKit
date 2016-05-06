//
//  YUNDialogConfiguration.m
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNDialogConfiguration.h"

#import "YUNMacros.h"

#define YUN_DIALOG_CONFIGURATION_APP_VERSIONS_KEY @"appVersions"
#define YUN_DIALOG_CONFIGURATION_NAME_KEY @"name"
#define YUN_DIALOG_CONFIGURATION_URL_KEY @"url"

@implementation YUNDialogConfiguration

#pragma mark - Object Lifecycle

- (instancetype)initWithName:(NSString *)name
                         URL:(NSURL *)URL
                 appVersions:(NSArray *)appVersions
{
    if ((self = [super init])) {
        _name = [name copy];
        _URL = [URL copy];
        _appVersions = [appVersions copy];
    }
    return self;
}

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithName:URL:appVersions:);
    return [self initWithName:nil URL:nil appVersions:nil];
}

#pragma mark NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSString *name = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_DIALOG_CONFIGURATION_NAME_KEY];
    NSURL *URL = [decoder decodeObjectOfClass:[NSURL class] forKey:YUN_DIALOG_CONFIGURATION_URL_KEY];
    NSSet *appVersionsClasses = [NSSet setWithObjects:[NSArray class],[NSNumber class], nil];
    NSArray *appVersions = [decoder decodeObjectOfClasses:appVersionsClasses forKey:YUN_DIALOG_CONFIGURATION_APP_VERSIONS_KEY];
    return [self initWithName:name URL:URL appVersions:appVersions];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_appVersions forKey:YUN_DIALOG_CONFIGURATION_APP_VERSIONS_KEY];
    [encoder encodeObject:_name forKey:YUN_DIALOG_CONFIGURATION_NAME_KEY];
    [encoder encodeObject:_URL forKey:YUN_DIALOG_CONFIGURATION_URL_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
