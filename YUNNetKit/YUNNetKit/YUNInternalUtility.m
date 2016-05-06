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

@end
