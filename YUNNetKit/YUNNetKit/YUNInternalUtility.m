//
//  YUNInternalUtility.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNInternalUtility.h"

#import <sys/time.h>
#import <mach-o/dyld.h>

#import "YUNUtility.h"
#import "YUNTypeUtility.h"
#import "YUNError.h"
#import "YUNSettings.h"

typedef NS_ENUM(NSUInteger, FBSDKInternalUtilityVersionMask)
{
    FBSDKInternalUtilityMajorVersionMask = 0xFFFF0000,
    //FBSDKInternalUtilityMinorVersionMask = 0x0000FF00, // unused
    //FBSDKInternalUtilityPatchVersionMask = 0x000000FF, // unused
};

typedef NS_ENUM(NSUInteger, FBSDKInternalUtilityVersionShift)
{
    FBSDKInternalUtilityMajorVersionShift = 16,
    //FBSDKInternalUtilityMinorVersionShift = 8, // unused
    //FBSDKInternalUtilityPatchVersionShift = 0, // unused
};

@implementation YUNInternalUtility


+ (id)convertRequestValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]]) {
        value = [(NSNumber *)value stringValue];
    } else if ([value isKindOfClass:[NSURL class]]) {
        value = [(NSURL *)value absoluteString];
    }
    return value;
}

+ (void)dictionary:(NSMutableDictionary *)dictionary setObject:(id)object forKey:(id<NSCopying>)key
{
    if (object && key) {
        [dictionary setObject:object forKey:key];
    }
}

+ (BOOL)object:(id)object isEqualToObject:(id)other;
{
    if (object == other) {
        return YES;
    }
    if (!object || !other) {
        return NO;
    }
    return [object isEqual:other];
}

+ (unsigned long)currentTimeInMilliseconds
{
    struct timeval time;
    gettimeofday(&time, NULL);
    return (time.tv_sec * 1000) + (time.tv_usec / 1000);
}

+ (BOOL)isOSRunTimeVersionAtLeast:(NSOperatingSystemVersion)version
{
    return ([self _compareOperatingSystemVersion:[self operatingSystemVersion] toVersion:version] != NSOrderedAscending);
}

+ (BOOL)isUIKitLinkTimeVersionAtLeast:(FBSDKUIKitVersion)version
{
    static int32_t linkTimeMajorVersion;
    static dispatch_once_t getVersionOnce;
    dispatch_once(&getVersionOnce, ^{
        int32_t linkTimeVersion = NSVersionOfLinkTimeLibrary("UIKit");
        linkTimeMajorVersion = ((MAX(linkTimeVersion, 0) & FBSDKInternalUtilityMajorVersionMask) >> FBSDKInternalUtilityMajorVersionShift);
    });
    return (version <= linkTimeMajorVersion);
}

+ (NSOperatingSystemVersion)operatingSystemVersion
{
    static NSOperatingSystemVersion operatingSystemVersion = {
        .majorVersion = 0,
        .minorVersion = 0,
        .patchVersion = 0,
    };
    static dispatch_once_t getVersionOnce;
    dispatch_once(&getVersionOnce, ^{
        if ([NSProcessInfo instancesRespondToSelector:@selector(operatingSystemVersion)]) {
            operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
        } else {
            NSArray *components = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
            switch (components.count) {
                default:
                case 3:
                    operatingSystemVersion.patchVersion = [components[2] integerValue];
                    // fall through
                case 2:
                    operatingSystemVersion.minorVersion = [components[1] integerValue];
                    // fall through
                case 1:
                    operatingSystemVersion.majorVersion = [components[0] integerValue];
                    break;
                case 0:
                    operatingSystemVersion.majorVersion = ([self isUIKitLinkTimeVersionAtLeast:FBSDKUIKitVersion_7_0] ? 7 : 6);
                    break;
            }
        }
    });
    return operatingSystemVersion;
}

+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary
                                  error:(NSError *__autoreleasing *)errorRef
                   invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler
{
    NSMutableString *queryString = [[NSMutableString alloc] init];
    __block BOOL hasParameters = NO;
    if (dictionary) {
        NSMutableArray *keys = [[dictionary allKeys] mutableCopy];
        // remove non-string keys, as they are not valid
        [keys filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject isKindOfClass:[NSString class]];
        }]];
        // sort the keys so that the query string order is deterministic
        [keys sortUsingSelector:@selector(compare:)];
        BOOL stop = NO;
        for (NSString *key in keys) {
            id value = [self convertRequestValue:dictionary[key]];
            if ([value isKindOfClass:[NSString class]]) {
                value = [YUNUtility URLEncode:value];
            }
            if (invalidObjectHandler && ![value isKindOfClass:[NSString class]]) {
                value = invalidObjectHandler(value, &stop);
                if (stop) {
                    break;
                }
            }
            if (value) {
                if (hasParameters) {
                    [queryString appendString:@"&"];
                }
                [queryString appendFormat:@"%@=%@", key, value];
                hasParameters = YES;
            }
        }
    }
    if (errorRef != NULL) {
        *errorRef = nil;
    }
    return ([queryString length] ? [queryString copy] : nil);
}

#pragma mark - Helper Methods

+ (NSComparisonResult)_compareOperatingSystemVersion:(NSOperatingSystemVersion)version1
                                           toVersion:(NSOperatingSystemVersion)version2
{
    if (version1.majorVersion < version2.majorVersion) {
        return NSOrderedAscending;
    } else if (version1.majorVersion > version2.majorVersion) {
        return NSOrderedDescending;
    } else if (version1.minorVersion < version2.minorVersion) {
        return NSOrderedAscending;
    } else if (version1.minorVersion > version2.minorVersion) {
        return NSOrderedDescending;
    } else if (version1.patchVersion < version2.patchVersion) {
        return NSOrderedAscending;
    } else if (version1.patchVersion > version2.patchVersion) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

+ (NSBundle *)bundleForStrings
{
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *stringsBundlePath = [[NSBundle mainBundle] pathForResource:@"FacebookSDKStrings"
                                                                      ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:stringsBundlePath] ?: [NSBundle mainBundle];
    });
    return bundle;
}

+ (void)extractPermissionsFromResponse:(NSDictionary *)responseObject
                    grantedPermissions:(NSMutableSet *)grantedPermissions
                   declinedPermissions:(NSMutableSet *)declinedPermissions
{
    NSArray *resultData = responseObject[@"data"];
    if (resultData.count > 0) {
        for (NSDictionary *permissionsDictionary in resultData) {
            NSString *permissionName = permissionsDictionary[@"permission"];
            NSString *status = permissionsDictionary[@"status"];
            
            if ([status isEqualToString:@"granted"]) {
                [grantedPermissions addObject:permissionName];
            } else if ([status isEqualToString:@"declined"]) {
                [declinedPermissions addObject:permissionName];
            }
        }
    }
}

+ (NSString *)JSONStringForObject:(id)object
                            error:(NSError *__autoreleasing *)errorRef
             invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler
{
    if (invalidObjectHandler || ![NSJSONSerialization isValidJSONObject:object]) {
        object = [self _convertObjectToJSONObject:object invalidObjectHandler:invalidObjectHandler stop:NULL];
        if (![NSJSONSerialization isValidJSONObject:object]) {
            if (errorRef != NULL) {
                *errorRef = [YUNError invalidArgumentErrorWithName:@"object"
                                                               value:object
                                                             message:@"Invalid object for JSON serialization."];
            }
            return nil;
        }
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:errorRef];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (id)_convertObjectToJSONObject:(id)object
            invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler
                            stop:(BOOL *)stopRef
{
    __block BOOL stop = NO;
    if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]) {
        // good to go, keep the object
    } else if ([object isKindOfClass:[NSURL class]]) {
        object = [(NSURL *)object absoluteString];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        [(NSDictionary *)object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *dictionaryStop) {
            [self dictionary:dictionary
                   setObject:[self _convertObjectToJSONObject:obj invalidObjectHandler:invalidObjectHandler stop:&stop]
                      forKey:[YUNTypeUtility stringValue:key]];
            if (stop) {
                *dictionaryStop = YES;
            }
        }];
        object = dictionary;
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (id obj in (NSArray *)object) {
            id convertedObj = [self _convertObjectToJSONObject:obj invalidObjectHandler:invalidObjectHandler stop:&stop];
            [self array:array addObject:convertedObj];
            if (stop) {
                break;
            }
        }
        object = array;
    } else {
        object = invalidObjectHandler(object, stopRef);
    }
    if (stopRef != NULL) {
        *stopRef = stop;
    }
    return object;
}

+ (void)array:(NSMutableArray *)array addObject:(id)object
{
    if (object) {
        [array addObject:object];
    }
}

+ (NSURL *)URLWithHostPrefix:(NSString *)hostPrefix
                        path:(NSString *)path
             queryParameters:(NSDictionary *)queryParameters
              defaultVersion:(NSString *)defaultVersion
                       error:(NSError *__autoreleasing *)errorRef
{
    if ([hostPrefix length] && ![hostPrefix hasPrefix:@"."]) {
        hostPrefix = [hostPrefix stringByAppendingString:@"."];
    }
    
    NSString *host = @"facebook.com";
    NSString *domainPart = [YUNSettings facebookDomainPart];
    if ([domainPart length]) {
        host = [[NSString alloc] initWithFormat:@"%@.%@", domainPart, host];
    }
    host = [NSString stringWithFormat:@"%@%@", hostPrefix ?: @"", host ?: @""];
    
    if ([path length]) {
        if (![path hasPrefix:@"/"]) {
            path = [@"/" stringByAppendingString:path];
        }
    }
    return [self URLWithScheme:@"https"
                          host:host
                          path:path
               queryParameters:queryParameters
                         error:errorRef];
}

+ (NSURL *)URLWithScheme:(NSString *)scheme
                    host:(NSString *)host
                    path:(NSString *)path
         queryParameters:(NSDictionary *)queryParameters
                   error:(NSError *__autoreleasing *)errorRef
{
    if (![path hasPrefix:@"/"]) {
        path = [@"/" stringByAppendingString:path ?: @""];
    }
    
    NSString *queryString = nil;
    if ([queryParameters count]) {
        NSError *queryStringError;
        queryString = [@"?" stringByAppendingString:[YUNUtility queryStringWithDictionary:queryParameters error:&queryStringError]];
        if (!queryString) {
            if (errorRef != NULL) {
                *errorRef = [YUNError invalidArgumentErrorWithName:@"queryParameters"
                                                             value:queryParameters
                                                           message:nil underlyingError:queryStringError];
            }
            return nil;
        }
    }
    
    NSURL *URL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@://%@%@%@",scheme ?: @"",
                                               host ?: @"",
                                               path ?: @"",
                                                queryString ?: @""]];
    if (errorRef != NULL) {
        if (URL) {
            *errorRef = nil;
        } else {
            *errorRef = [YUNError unknownErrorWithMessage:@"Unknown error building URL."];
        }
    }
    return URL;
}

@end
