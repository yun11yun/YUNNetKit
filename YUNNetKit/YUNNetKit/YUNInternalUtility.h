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
 @abstract Constructs the scheme for apps that come to the current app through the bridge.
 */
+ (NSString *)appURLScheme;

/**
 *  Constructs an URL for the current app.
 *
 *  @param host            The host for URL
 *  @param path            The path for the URL
 *  @param queryParameters The query parameters for the URL, This will be converted into a query string.
 *  @param errorRef        If an error occurs, upon return contains an NSError object that descrobes the problem.
 *
 *  @return The app URL
 */
+ (NSURL *)appURLWithHost:(NSString *)host
                     path:(NSString *)path
          queryParameters:(NSDictionary *)queryParameters
                    error:(NSError *__autoreleasing *)errorRef;

/**
 *  Parses an url's query params (and potentially fragment) into a dictionary
 *
 *  @param url The url
 *
 *  @return A dictionary with the key/value pairs.
 */
+ (NSDictionary *)dictionaryFromURL:(NSURL *)url;

/*!
 @abstract Adds an object to an array if it is not nil.
 @param array The array to add the object to.
 @param object The object to add to the array.
 */
+ (void)array:(NSMutableArray *)array addObject:(id)object;

/*!
 @abstract Returns bundle for returning localized strings
 @discussion We assume a convention of a bundle named FBSDKStrings.bundle, otherwise we
 return the main bundle.
 */
+ (NSBundle *)bundleForStrings;

/*!
 @abstract Converts simple value types to the string equivelant for serializing to a request query or body.
 @param value The value to be converted.
 @return The value that may have been converted if able (otherwise the input param).
 */
+ (id)convertRequestValue:(id)value;

/*!
 @abstract Gets the milliseconds since the Unix Epoch.
 @discussion Changes in the system clock will affect this value.
 @return The number of milliseconds since the Unix Epoch.
 */
+ (unsigned long)currentTimeInMilliseconds;

/**
 *  Sets an object for a key in a dictionary if it is not nil.
 *
 *  @param dictionary The dictionary to set the value for.
 *  @param object     The value to set after serializing to JSON.
 *  @param key        The key to set the value for.
 *  @param errorRef   If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return NO if an error occurred while serializing the object, otherwise YES.
 */
+ (BOOL)dictionary:(NSMutableDictionary *)dictionary
setJSONStringForObject:(id)object
            forKey:(id<NSCopying>)key
             error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Sets an object for a key in a dictionary if it is not nil.
 @param dictionary The dictionary to set the value for.
 @param object The value to set.
 @param key The key to set the value for.
 */
+ (void)dictionary:(NSMutableDictionary *)dictionary setObject:(id)object forKey:(id<NSCopying>)key;


/*!
 @abstract Constructs a URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param defaultVersion A version to add to the URL if none is found in the path.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
+ (NSURL *)URLWithHostPrefix:(NSString *)hostPrefix
                        path:(NSString *)path
             queryParameters:(NSDictionary *)queryParameters
              defaultVersion:(NSString *)defaultVersion
                       error:(NSError *__autoreleasing *)errorRef;

/*!
 @abstract Constructs an NSURL.
 @param scheme The scheme for the URL.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The URL.
 */
+ (NSURL *)URLWithScheme:(NSString *)scheme
                    host:(NSString *)host
                    path:(NSString *)path
         queryParameters:(NSDictionary *)queryParameters
                   error:(NSError *__autoreleasing *)errorRef;

/**
 *  Tests whether the supplied URL is valid URL for opening in the browser.
 *
 *  @param URL The URL to test.
 *
 *  @return YES if the URL refers to an http or https resource, otherwise NO.
 */
+ (BOOL)isBrowserURL:(NSURL *)URL;

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
 @abstract Converts an object into a JSON string.
 @param object The object to convert to JSON.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @param invalidObjectHandler Handles objects that are invalid, returning a replacement value or nil to ignore.
 @return A JSON string or nil if the object cannot be converted to JSON.
 */
+ (NSString *)JSONStringForObject:(id)object
                            error:(NSError *__autoreleasing *)errorRef
             invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler;

/*!
 @abstract Checks equality between 2 objects.
 @discussion Checks for pointer equality, nils, isEqual:.
 @param object The first object to compare.
 @param other The second object to compare.
 @result YES if the objects are equal, otherwise NO.
 */
+ (BOOL)object:(id)object isEqualToObject:(id)other;

/*!
 @abstract Converts a JSON string into an object
 @param string The JSON string to convert.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return An NSDictionary, NSArray, NSString or NSNumber containing the object representation, or nil if the string
 cannot be converted.
 */
+ (id)objectForJSONString:(NSString *)string error:(NSError *__autoreleasing *)errorRef;

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
 @abstract Extracts permissions from a response fetched from me/permissions
 @param responseObject the response
 @param grantedPermissions the set to add granted permissions to
 @param declinedPermissions the set to add decliend permissions to.
 */
+ (void)extractPermissionsFromResponse:(NSDictionary *)responseObject
                    grantedPermissions:(NSMutableSet *)grantedPermissions
                   declinedPermissions:(NSMutableSet *)declinedPermissions;

/**
 @abstract Attempts to find the first UIViewController in the view's responder chain. Returns nil if not found.
 */
+ (UIViewController *)viewControllerForView:(UIView *)view;


#define YUNConditionalLog(condition, loggingBehavior, desc, ...) \
{ \
if (!(condition)) { \
NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
[FBSDKLogger singleShotLogEntry:loggingBehavior logEntry:msg]; \
} \
}

@end
