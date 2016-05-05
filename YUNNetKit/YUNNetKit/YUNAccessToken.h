//
//  YUNAccessToken.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * @abstract Notification indicating that the 'currentAccessToken' has changed.
 * @discussion the userInfo dictionary of the notification will contain keys
 `YUNAccessTokenChangeOldKey` and
 `YUNAccessTokenChangeNewKey`.
 */
extern NSString *const YUNAccessTokenDidChangeNotification;

/*!
 @abstract A key in the notification's userInfo that will be set
 if and only if the user ID changed between the old and new tokens.
 @discussion Token refreshes can occur automatically with the SDK
 which do not change the user. If you're only interested in user
 changes (such as logging out), you should check for the existence
 of this key. The value is a NSNumber with a boolValue.
 
 On a fresh start of the app where the SDK reads in the cached value
 of an access token, this key will also exist since the access token
 is moving from a null state (no user) to a non-null state (user).
 */
extern NSString *const YUNAccessTokenDidChangeUserID;

/*
 @abstract key in notification's userInfo object for getting the old token.
 @discussion If there was no old token, the key will not be present.
 */
extern NSString *const YUNAccessTokenChangeOldKey;

/*
 @abstract key in notification's userInfo object for getting the new token.
 @discussion If there is no new token, the key will not be present.
 */
extern NSString *const YUNAccessTokenChangeNewKey;

/*
 * @class YUNAccessToken
 * @abstract Represents an immutable access token for using YUNNetKit services
 */
@interface YUNAccessToken : NSObject<NSCopying, NSSecureCoding>

// Returns the app ID.
@property (nonatomic, copy, readonly) NSString *appID;

// Returns the known declined permissions.
@property (nonatomic, copy, readonly) NSSet *declinedPermissions;

// Returns the expiration date.
@property (nonatomic, copy, readonly) NSDate *expirationDate;

// Returns the known granted permissions.
@property (nonatomic, copy, readonly) NSSet *permissions;

// Returns the date the token was last refreshed.
@property (nonatomic, copy, readonly) NSDate *refreshDate;

// Returns the opanue token string.
@property (nonatomic, copy, readonly) NSString *tokenString;

// Returns the user ID.
@property (nonatomic, copy, readonly) NSString *userID;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTokenString:(NSString *)tokenString
                        permissions:(NSArray *)permissions
                declinedPermissions:(NSArray *)declinedPermissions
                              appID:(NSString *)appID
                             userID:(NSString *)userID
                     expirationDate:(NSDate *)expirationDate
                        refreshDate:(NSDate *)refreshDate
NS_DESIGNATED_INITIALIZER;

/*!
 @abstract Convenience getter to determine if a permission has been granted
 @param permission  The permission to check.
 */
- (BOOL)hasGranted:(NSString *)permission;

/*!
 @abstract Compares the receiver to another FBSDKAccessToken
 @param token The other token
 @return YES if the receiver's values are equal to the other token's values; otherwise NO
 */
- (BOOL)isEqualToAccessToken:(YUNAccessToken *)token;

/*!
 @abstract Returns the "global" access token that represents the currently logged in user.
 @discussion The `currentAccessToken` is a convenient representation of the token of the
 current user and is used by other SDK components.
 */
+ (YUNAccessToken *)currentAccessToken;

/*!
 @abstract Sets the "global" access token that represents the currently logged in user.
 @param token The access token to set.
 @discussion This will broadcast a notification and save the token to the app keychain.
 */
+ (void)setCurrentAccessToken:(YUNAccessToken *)token;

/*!
 @abstract Refresh the current access token's permission state and extend the token's expiration date,
 if possible.
 @param completionHandler an optional callback handler that can surface any errors related to permission refreshing.
 @discussion On a successful refresh, the currentAccessToken will be updated so you typically only need to
 observe the `YUNAccessTokenDidChangeNotification` notification.
 
 If a token is already expired, it cannot be refreshed.
 */

//+ (void)refreshCurrentAccessToken:(YUNRequestHandler)completionHandler;

@end
