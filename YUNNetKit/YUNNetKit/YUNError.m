//
//  YUNError.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNError.h"

#import "YUNContants.h"
#import "YUNInternalUtility.h"
#import "YUNTypeUtility.h"
#import "YUNMacros.h"

@implementation YUNError

#pragma mark - Class Methods

+ (NSString *)errorDomain
{
    return YUNErrorDomain;
}

+ (BOOL)errorIsNetworkError:(NSError *)error
{
    if (error == nil) {
        return NO;
    }
    
    NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
    if ([self errorIsNetworkError:innerError]) {
        return YES;
    }
    
    switch (error.code) {
        case NSURLErrorTimedOut:
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorInternationalRoamingOff:
        case NSURLErrorCallIsActive:
        case NSURLErrorDataNotAllowed:
            return YES;
        default:
            return NO;
    }
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message
{
    return [self errorWithCode:code message:message underlyingError:nil];
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message underlyingError:(NSError *)underlyingError
{
    return [self errorWithCode:code userInfo:nil message:message underlyingError:underlyingError];
}

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo message:(NSString *)message underlyingError:(NSError *)underlyingError
{
    NSMutableDictionary *fullUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
    [YUNInternalUtility dictionary:fullUserInfo setObject:message forKey:YUNErrorDeveloperMessageKey];
    [YUNInternalUtility dictionary:fullUserInfo setObject:message forKey:NSUnderlyingErrorKey];
    userInfo = ([fullUserInfo count] ? [fullUserInfo copy] : nil);
    return [[NSError alloc] initWithDomain:[self errorDomain] code:code userInfo:userInfo];
}

+ (NSError *)invalidArgumentErrorWithName:(NSString *)name value:(id)value message:(NSString *)message
{
    return [self invalidArgumentErrorWithName:name value:value message:message underlyingError:nil];
}

+ (NSError *)invalidArgumentErrorWithName:(NSString *)name value:(id)value message:(NSString *)message underlyingError:(NSError *)underlyingError
{
    if (!message) {
        message = [[NSString alloc] initWithFormat:@"Invalid value for %@: %@",name, value];
    }
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [YUNInternalUtility dictionary:userInfo setObject:name forKey:YUNErrorArgumentNameKey];
    [YUNInternalUtility dictionary:userInfo setObject:value forKey:YUNErrorArgumentValueKey];
    return [self errorWithCode:YUNInvalidArgumentErrorCode
                      userInfo:userInfo
                       message:message
               underlyingError:underlyingError];
}

+ (NSError *)invalidCollectionErrorWithName:(NSString *)name
                                 collection:(id<NSFastEnumeration>)collection
                                       item:(id)item
                                    message:(NSString *)message
{
    return [self invalidCollectionErrorWithName:name collection:collection item:item message:message underlyingError:nil];
}

+ (NSError *)invalidCollectionErrorWithName:(NSString *)name
                                 collection:(id<NSFastEnumeration>)collection
                                       item:(id)item
                                    message:(NSString *)message
                            underlyingError:(NSError *)underlyingError
{
    if (!message) {
        message = [[NSString alloc] initWithFormat:@"Invalid item (%@) found in collection for %@: %@",item, name, collection];
    }
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [YUNInternalUtility dictionary:userInfo setObject:name forKey:YUNErrorArgumentNameKey];
    [YUNInternalUtility dictionary:userInfo setObject:item forKey:YUNErrorArgumentValueKey];
    [YUNInternalUtility dictionary:userInfo setObject:collection forKey:YUNErrorArgumentCollectionKey];
    return [self errorWithCode:YUNInvalidArgumentErrorCode
                      userInfo:userInfo
                       message:message
               underlyingError:underlyingError];
}

+ (NSError *)requiredArgumentErrorWithName:(NSString *)name message:(NSString *)message
{
    return [self requiredArgumentErrorWithName:name message:message underlyingError:nil];
}

+ (NSError *)requiredArgumentErrorWithName:(NSString *)name
                                   message:(NSString *)message
                           underlyingError:(NSError *)underlyingError
{
    if (!message) {
        message = [[NSString alloc] initWithFormat:@"Value for %@ is required.", name];
    }
    return [self invalidArgumentErrorWithName:name value:nil message:message underlyingError:underlyingError];
}

+ (NSError *)unknownErrorWithMessage:(NSString *)message
{
    return [self errorWithCode:YUNUnknownErrorCode
                      userInfo:nil
                       message:message
               underlyingError:nil];
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

@end
