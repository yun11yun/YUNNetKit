//
//  YUNContants.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNMacros.h"

/*
 * @abstract The error domain for all errors from YUNNetKit
 * @discussion Error codes from the SDK in the range 0-99 are reserved for  this domain.
 */
extern NSString *const YUNErrorDomain;

/**
 * @typedef NS_ENUM(NSInteger, YUNErrorCode)
 * @abstract Error codes for YUNErrorDomain.
 */
typedef NS_ENUM(NSInteger, YUNErrorCode)
{
    // Reserved.
    YUNReservedErrorCode = 0,
    
    // The error code for errors from invalid encryption on incoming encryption URLs.
    YUNEncryptionErrorCode,
    
    // The error code for errors from invalid arguments to SDK methods.
    YUNInvalidArgumentErrorCode,
    
    // The error code for unknown errors.
    YUNUnknownErrorCode,
    
    // A request failed due to a network error. Use NSUnderlyingErrorKey to retrieve the error object from the NSURLConnection for more information.
    YUNNetworkErrorCode,
    
    // The error code for errors encounted during an App Events flush.
    YUNAppEventsFlushErrorCode,
    
    // An endpoint that returns a binary response was used with YUNRequestConnection.
    // @discussion Endpoints that return image/jpg,etc. should be accessed using NSURLRequest
    YUNRequestNotTextMimeTypeReturnedErrorCode,
    
    // The operation failed because the server returned an unexpected response.
    // @discussion You can get this error if you are not using the most recent SDK, or you are accessing a version of the Graph API incompatible with the current SDK.
    YUNRequestProtocolMismatchErrorCode,
    
    // The API returned an error.
    // @discussion See below for useful userInfo keys (beginning wieht YUNRequestError*)
    YUNRequestAPIErrorCode,
    
    // The specified dialog cinfiguration is not available.
    // @discussion This error may singify that the configuration for the dialogs has not yet been downloaded from the server or that the dialog is unavailabel. Subsequent attempts to use the dialog may successed as the configuration is loaded.
    YUNDialogUnavailableErrorCode,
    
    // Indicated an operation failed because a required access token was not found.
    YUNAccessTokenRequiredErrorCode,
    
    // Indicated an app switch (typically for a dialog) failed because the destination app is out of date.
    YUNAppVersionUnsupportedErrorCode,
    
    // Indicated an app switch to the browser (typically for a dialog) failed.
    YUNBrowserUnavailableErrorCode,
};

/**
 * @typedef NS_ENUM(NSUInteger, YUNRequestErrorCategory)
 * @abstract Describes the category of error. See 'YUNRequestErrorCategoryKey'.
 */
typedef NS_ENUM(NSUInteger, YUNRequestErrorCategory)
{
    // The default error category that is not known to be recoverable. Check 'YUNLocalizedErrorDescriptionKey' for a user facing message.
    YUNRequestErrorCategoryOther = 0,
    
    // Indicates the error is temporary (such as server throttling). While a recoveryAttempter will be provided with the error instance, the attempt is guaranteed to succeed so you can simply retry the operation if you do not want to present an alert.
    YUNRequestErrorCategoryTransient = 1,
    
    // Indicated the error can be recovered (such as requiring a login). A recoveryAttempter will be provided with the error instance that can take UI action.
    YUNRequestErrorCategoryRecoverable = 2,
};

/**
 * @abstract The userInfo key for the invalid collection for errors with YUNInvalidArgumentErrorCode.
 * @discussion If the invalid argument is a collection, the collection can be found with this key and the individual invalid item can be found with YUNErrorArgumentValueKey.
 */
extern NSString *const YUNErrorArgumentCollectionKey;

// The userInfo key for the invalid argument name for errors with YUNInvalidArgumentErrorCode.
extern NSString *const YUNErrorArgumentNameKey;

// The userInfo key for the invalid argument value for errors with YUNInvalidArgumentErrorCode.
extern NSString *const YUNErrorArgumentValueKey;

/*!
 @abstract The userInfo key for the message for developers in NSErrors that originate from the SDK.
 @discussion The developer message will not be localized and is not intended to be presented within the app.
 */
extern NSString *const YUNErrorDeveloperMessageKey;

/*!
 @abstract The userInfo key describing a localized description that can be presented to the user.
 */
extern NSString *const YUNErrorLocalizedDescriptionKey;

/*!
 @abstract The userInfo key describing a localized title that can be presented to the user, used with `YUNLocalizedErrorDescriptionKey`.
 */
extern NSString *const YUNErrorLocalizedTitleKey;

/*
 @methodgroup YUNRequest error userInfo keys
 */

/*!
 @abstract The userInfo key describing the error category, for error recovery purposes.
 @discussion See `YUNErrorRecoveryProcessor` and `[YUNRequest disableErrorRecovery]`.
 */
extern NSString *const YUNRequestErrorCategoryKey;

// The userInfo key for the API error code.
extern NSString *const YUNRequestErrorGraphErrorCode;

// The userInfo key for the API error subcode.
extern NSString *const YUNRequestErrorGraphErrorSubcode;

// The userInfo key for the HTTP status code.
extern NSString *const YUNRequestErrorHTTPStatusCodeKey;

// The userInfo key for the raw JSON response.
extern NSString *const YUNRequestErrorParsedJSONResponseKey;

/*!
 @abstract a formal protocol very similar to the informal protocol NSErrorRecoveryAttempting
 */
@protocol FBSDKErrorRecoveryAttempting<NSObject>

/*!
 @abstract attempt the recovery
 @param error the error
 @param recoveryOptionIndex the selected option index
 @param delegate the delegate
 @param didRecoverSelector the callback selector, see discussion.
 @param contextInfo context info to pass back to callback selector, see discussion.
 @discussion
 Given that an error alert has been presented document-modally to the user, and the user has chosen one of the error's recovery options, attempt recovery from the error, and send the selected message to the specified delegate. The option index is an index into the error's array of localized recovery options. The method selected by didRecoverSelector must have the same signature as:
 
 - (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo;
 
 The value passed for didRecover must be YES if error recovery was completely successful, NO otherwise.
 */
- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo;

@end
