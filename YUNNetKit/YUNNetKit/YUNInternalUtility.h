//
//  YUNInternalUtility.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(int32_t, FBSDKUIKitVersion)
{
    FBSDKUIKitVersion_6_0 = 0x0944,
    FBSDKUIKitVersion_6_1 = 0x094C,
    FBSDKUIKitVersion_7_0 = 0x0B57,
    FBSDKUIKitVersion_7_1 = 0x0B77,
    FBSDKUIKitVersion_8_0 = 0x0CF6,
};

@interface YUNInternalUtility : NSObject

/*!
 @abstract Sets an object for a key in a dictionary if it is not nil.
 @param dictionary The dictionary to set the value for.
 @param object The value to set.
 @param key The key to set the value for.
 */
+ (void)dictionary:(NSMutableDictionary *)dictionary setObject:(id)object forKey:(id<NSCopying>)key;

/*!
 @abstract Checks equality between 2 objects.
 @discussion Checks for pointer equality, nils, isEqual:.
 @param object The first object to compare.
 @param other The second object to compare.
 @result YES if the objects are equal, otherwise NO.
 */
+ (BOOL)object:(id)object isEqualToObject:(id)other;

/*!
 @abstract Gets the milliseconds since the Unix Epoch.
 @discussion Changes in the system clock will affect this value.
 @return The number of milliseconds since the Unix Epoch.
 */
+ (unsigned long)currentTimeInMilliseconds;

/*!
 @abstract Tests whether the operating system is at least the specified version.
 @param version The version to test against.
 @return YES if the operating system is greater than or equal to the specified version, otherwise NO.
 */
+ (BOOL)isOSRunTimeVersionAtLeast:(NSOperatingSystemVersion)version;

/*!
 @abstract Tests whether the UIKit version that the current app was linked to is at least the specified version.
 @param version The version to test against.
 @return YES if the linked UIKit version is greater than or equal to the specified version, otherwise NO.
 */
+ (BOOL)isUIKitLinkTimeVersionAtLeast:(FBSDKUIKitVersion)version;

/*!
 @abstract The version of the operating system on which the process is executing.
 */
+ (NSOperatingSystemVersion)operatingSystemVersion;

/*!
 @abstract Constructs a query string from a dictionary.
 @param dictionary The dictionary with key/value pairs for the query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @param invalidObjectHandler Handles objects that are invalid, returning a replacement value or nil to ignore.
 @result Query string representation of the parameters.
 */
+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary
                                  error:(NSError *__autoreleasing *)errorRef
                   invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler;

/*!
 @abstract Converts simple value types to the string equivelant for serializing to a request query or body.
 @param value The value to be converted.
 @return The value that may have been converted if able (otherwise the input param).
 */
+ (id)convertRequestValue:(id)value;

/*!
 @abstract Returns bundle for returning localized strings
 @discussion We assume a convention of a bundle named FBSDKStrings.bundle, otherwise we
 return the main bundle.
 */
+ (NSBundle *)bundleForStrings;

@end
