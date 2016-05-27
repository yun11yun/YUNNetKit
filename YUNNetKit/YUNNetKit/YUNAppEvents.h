//
//  YUNAppEvents.h
//  YUNNetKit
//
//  Created by Orange on 5/20/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNMacros.h"

@class YUNAccessToken;
@class YUNRequest;

/**
 *  @abstract NSNotficationCenter name indicating a result of a failed log flush attempt. The posted object will be an NSError instance.
 */
extern NSString *const YUNAppEventsLoggingResultNotification;

/*! @abstract optional plist key ("FacebookLoggingOverrideAppID") for setting `loggingOverrideAppID` */
extern NSString *const YUNAppEventsOverrideAppIDBundleKey;

/**
 *  @typedef NS_ENUM (NSUInteger, YUNAppEventsFlushBehavior)
 *  @abstract Specifies when 'YUNAppEvents' sends log events to the server.
 */
typedef NS_ENUM(NSUInteger, YUNAppEventsFlushBehavior)
{
    /**
     *  Flush automatically: periodically (once a minute or every 100 logged events) and always at app reactivation.
     */
    YUNAppEventsFlushBehaviorAuto = 0,
    
    /**
     *  Only flush when the 'flush' method is called. When an app is moved to background/terminated, the 
     events are
     */
    YUNAppEventsFlushBehaviorExplicitOnly,
};

// Log this event when the user has achieved a level in the app.
extern NSString *const YUNAppEventNameAchievedLevel;

// Log this event when the user has entered their payment info.
extern NSString *const YUNAppEventNameAddedPaymentInfo;

// Log this event when the user has added an item to their cart. The valueToSum passed to logEvent should be the item's price.
extern NSString *const YUNAppEventNameAddedToCart;

// Log this event when the user has added an item to their wishlist. The valueToSum passed to logEvent should be the item's price.
extern NSString *const YUNAppEventNameAddedToWidhlist;

// Log this event when the user has completed registration with the app.
extern NSString *const YUNAppEventNameCompletedRegistration;

// Log this event when the user has completed a tutorial in the app.
extern NSString *const YUNAppEventNameCompletedTutorial;

// Log this event when the user has entered the checkout process. The valueToSum passed to logEvent should be the total price in the cart.
extern NSString *const YUNAppEventNameInitiatedCheckout;

// Log this event when the user has rated an item in the app. The valueToSum passed to logEvent should be the numberic rating.
extern NSString *const YUNAppEventNameRated;

// Log this event when the user has performed a search within the app.
extern NSString *const YUNAppEventNameSearched;

// Log this event when the user has spent app credits. The valueToSum passed to logEvent should be the number of credits spent.
extern NSString *const YUNAppEventNameSpentCredits;

// Log this event when the user has unlocked an achievement in the app.
extern NSString *const YUNAppEventNameUnlockedAchievement;

// Log this event when the user has viewed a form of content in the app.
extern NSString *const YUNAppEventNameViewedContent;

/*!
 @methodgroup Predefined event name parameters for common additional information to accompany events logged through the `logEvent` family
 of methods on `YUNAppEvents`.  Common event names are provided in the `FBAppEventName*` constants.
 */

/*! Parameter key used to specify an ID for the specific piece of content being logged about.  Could be an EAN, article identifier, etc., depending on the nature of the app. */
extern NSString *const YUNAppEventParameterNameContentID;

/*! Parameter key used to specify a generic content type/family for the logged event, e.g. "music", "photo", "video".  Options to use will vary based upon what the app is all about. */
extern NSString *const YUNAppEventParameterNameContentType;

/*! Parameter key used to specify currency used with logged event.  E.g. "USD", "EUR", "GBP".  See ISO-4217 for specific values.  One reference for these is */
extern NSString *const YUNAppEventParameterNameCurrency;

/*! Parameter key used to specify a description appropriate to the event being logged.  E.g., the name of the achievement unlocked in the `YUNAppEventNameAchievementUnlocked` event. */
extern NSString *const YUNAppEventParameterNameDescription;

/*! Parameter key used to specify the level achieved in a `YUNAppEventNameAchieved` event. */
extern NSString *const YUNAppEventParameterNameLevel;

/*! Parameter key used to specify the maximum rating available for the `YUNAppEventNameRate` event.  E.g., "5" or "10". */
extern NSString *const YUNAppEventParameterNameMaxRatingValue;

/*! Parameter key used to specify how many items are being processed for an `YUNAppEventNameInitiatedCheckout` or `YUNAppEventNamePurchased` event. */
extern NSString *const YUNAppEventParameterNameNumItems;

/*! Parameter key used to specify whether payment info is available for the `YUNAppEventNameInitiatedCheckout` event.  `YUNAppEventParameterValueYes` and `YUNAppEventParameterValueNo` are good canonical values to use for this parameter. */
extern NSString *const YUNAppEventParameterNamePaymentInfoAvailable;

/*! Parameter key used to specify method user has used to register for the app, e.g., "Facebook", "email", "Twitter", etc */
extern NSString *const YUNAppEventParameterNameRegistrationMethod;

/*! Parameter key used to specify the string provided by the user for a search operation. */
extern NSString *const YUNAppEventParameterNameSearchString;

/*! Parameter key used to specify whether the activity being logged about was successful or not.  `YUNAppEventParameterValueYes` and `YUNAppEventParameterValueNo` are good canonical values to use for this parameter. */
extern NSString *const YUNAppEventParameterNameSuccess;

/*
 @methodgroup Predefined values to assign to event parameters that accompany events logged through the `logEvent` family
 of methods on `YUNAppEvents`.  Common event parameters are provided in the `YUNAppEventParameterName*` constants.
 */

/*! Yes-valued parameter value to be used with parameter keys that need a Yes/No value */
extern NSString *const YUNAppEventParameterValueYes;

/*! No-valued parameter value to be used with parameter keys that need a Yes/No value */
extern NSString *const YUNAppEventParameterValueNo;

@interface YUNAppEvents : NSObject

/**
 * Basic event logging
 */

/*！
 
 @abstract 
 Log an event with just an eventName;
 
 @param eventName  The name of the event to record. Limitations on number of events and name length
 are given in the 'YUNAppEvents' documentation.
 
 */
+ (void)logEvent:(NSString *)eventName;

/**
 *  @abstract Log an event with an eventName and a numeric value to be aggregated with other events of this name.
 *
 *  @param eventName  The name of the event to record. Limitations on number of events and name length are given in the 'YUNAppEvents' doucumentation. Common event names are provided in 'YUNAppEventName*' constatns.
 
 *  @param valueToSum Amount to be aggregated into all events of this eventName, and App Insights will report the cumulative and average value of this amount.
 */
+ (void)logEvent:(NSString *)eventName valueToSum:(double)valueToSum;

/**
 *  @abstract Log event with an eventName and a set of key/value pairs in the parameters dictionary.
 *
 *  @param eventName  The name of the event to record. Limitations on number of events and name length are given in the 'YUNAppEvents' doucumentation. Common event names are provided in 'YUNAppEventName*' constatns.
 
 *  @param parameters Arbitrary parameter dictionary of charactristics. The keys to this dictionary must be NSString's, and the values are expected to be NSString or NSNumber. Limit
 */
+ (void)logEvent:(NSString *)eventName
      parameters:(NSDictionary *)parameters;

/*!
 
 @abstract
 Log an event with an eventName, a numeric value to be aggregated with other events of this name,
 and a set of key/value pairs in the parameters dictionary.
 
 @param eventName   The name of the event to record.  Limitations on number of events and name construction
 are given in the `YUNAppEvents` documentation.  Common event names are provided in `YUNAppEventName*` constants.
 
 @param valueToSum  Amount to be aggregated into all events of this eventName, and App Insights will report
 the cumulative and average value of this amount.
 
 @param parameters  Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
 be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
 parameters and name construction are given in the `FBSDKAppEvents` documentation.  Commonly used parameter names
 are provided in `YUNAppEventParameterName*` constants.
 
 */
+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary *)parameters;

/*!
 
 @abstract
 Log an event with an eventName, a numeric value to be aggregated with other events of this name,
 and a set of key/value pairs in the parameters dictionary.  Providing session lets the developer
 target a particular <YUNSession>.  If nil is provided, then `[YUNSession activeSession]` will be used.
 
 @param eventName   The name of the event to record.  Limitations on number of events and name construction
 are given in the `FBSDKAppEvents` documentation.  Common event names are provided in `FBAppEventName*` constants.
 
 @param valueToSum  Amount to be aggregated into all events of this eventName, and App Insights will report
 the cumulative and average value of this amount.  Note that this is an NSNumber, and a value of `nil` denotes
 that this event doesn't have a value associated with it for summation.
 
 @param parameters  Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
 be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
 parameters and name construction are given in the `YUNAppEvents` documentation.  Commonly used parameter names
 are provided in `YUNAppEventParameterName*` constants.
 
 @param accessToken  The optional access token to log the event as.
 */
+ (void)logEvent:(NSString *)eventName
      valueToSum:(NSNumber *)valueToSum
      parameters:(NSDictionary *)parameters
     accessToken:(YUNAccessToken *)accessToken;

/*
 * Purchase logging
 */

/*!
 
 @abstract
 Log a purchase of the specified amount, in the specified currency.
 
 @param purchaseAmount    Purchase amount to be logged, as expressed in the specified currency.  This value
 will be rounded to the thousandths place (e.g., 12.34567 becomes 12.346).
 
 @param currency          Currency, is denoted as, e.g. "USD", "EUR", "GBP".  See ISO-4217 for
 specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
 
 @discussion              This event immediately triggers a flush of the `YUNAppEvents` event queue, unless the `flushBehavior` is set
 to `YUNAppEventsFlushBehaviorExplicitOnly`.
 
 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency;

/*!
 
 @abstract
 Log a purchase of the specified amount, in the specified currency, also providing a set of
 additional characteristics describing the purchase.
 
 @param purchaseAmount  Purchase amount to be logged, as expressed in the specified currency.This value
 will be rounded to the thousandths place (e.g., 12.34567 becomes 12.346).
 
 @param currency        Currency, is denoted as, e.g. "USD", "EUR", "GBP".  See ISO-4217 for
 specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
 
 @param parameters      Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
 be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
 parameters and name construction are given in the `FBSDKAppEvents` documentation.  Commonly used parameter names
 are provided in `YUNAppEventParameterName*` constants.
 
 @discussion              This event immediately triggers a flush of the `YUNAppEvents` event queue, unless the `flushBehavior` is set
 to `YUNAppEventsFlushBehaviorExplicitOnly`.
 
 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters;

/*!
 
 @abstract
 Log a purchase of the specified amount, in the specified currency, also providing a set of
 additional characteristics describing the purchase, as well as an <YUNSession> to log to.
 
 @param purchaseAmount  Purchase amount to be logged, as expressed in the specified currency.This value
 will be rounded to the thousandths place (e.g., 12.34567 becomes 12.346).
 
 @param currency        Currency, is denoted as, e.g. "USD", "EUR", "GBP".  See ISO-4217 for
 specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
 
 @param parameters      Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
 be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
 parameters and name construction are given in the `YUNAppEvents` documentation.  Commonly used parameter names
 are provided in `YUNAppEventParameterName*` constants.
 
 @param accessToken  The optional access token to log the event as.
 
 @discussion            This event immediately triggers a flush of the `YUNAppEvents` event queue, unless the `flushBehavior` is set
 to `YUNAppEventsFlushBehaviorExplicitOnly`.
 
 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters
        accessToken:(YUNAccessToken *)accessToken;

/*!
 
 @abstract
 Notifies the events system that the app has launched and, when appropriate, logs an "activated app" event.  Should typically be placed in the
 app delegates' `applicationDidBecomeActive:` method.
 
 This method also takes care of logging the event indicating the first time this app has been launched, which, among other things, is used to
 track user acquisition and app install ads conversions.
 
 @discussion
 `activateApp` will not log an event on every app launch, since launches happen every time the app is backgrounded and then foregrounded.
 "activated app" events will be logged when the app has not been active for more than 60 seconds.  This method also causes a "deactivated app"
 event to be logged when sessions are "completed", and these events are logged with the session length, with an indication of how much
 time has elapsed between sessions, and with the number of background/foreground interruptions that session had.  This data
 is all visible in your app's App Events Insights.
 */
+ (void)activateApp;

/*
 * Control over event batching/flushing
 */

/*!
 
 @abstract
 Get the current event flushing behavior specifying when events are sent back to Facebook servers.
 */
+ (YUNAppEventsFlushBehavior)flushBehavior;

/*!

@abstract
Set the current event flushing behavior specifying when events are sent back to Facebook servers.

@param flushBehavior   The desired `YUNAppEventsFlushBehavior` to be used.
*/
+ (void)setFlushBehavior:(YUNAppEventsFlushBehavior)flushBehavior;

/*!
 @abstract
 Set the 'override' App ID for App Event logging.
 
 @discussion
 In some cases, apps want to use one Facebook App ID for login and social presence and another
 for App Event logging.  (An example is if multiple apps from the same company share an app ID for login, but
 want distinct logging.)  By default, this value is `nil`, and defers to the `FBSDKAppEventsOverrideAppIDBundleKey`
 plist value.  If that's not set, it defaults to `[FBSDKSettings appID]`.
 
 This should be set before any other calls are made to `FBSDKAppEvents`.  Thus, you should set it in your application
 delegate's `application:didFinishLaunchingWithOptions:` delegate.
 
 @param appID The Facebook App ID to be used for App Event logging.
 */
+ (void)setLoggingOverrideAppID:(NSString *)appID;

/*!
 @abstract
 Get the 'override' App ID for App Event logging.
 
 @see setLoggingOverrideAppID:
 
 */
+ (NSString *)loggingOverrideAppID;


/*!
 @abstract
 Explicitly kick off flushing of events to Facebook.  This is an asynchronous method, but it does initiate an immediate
 kick off.  Server failures will be reported through the NotificationCenter with notification ID `FBSDKAppEventsLoggingResultNotification`.
 */
+ (void)flush;

/*!
 @abstract
 Creates a request representing the Graph API call to retrieve a Custom Audience "third party ID" for the app's Facebook user.
 Callers will send this ID back to their own servers, collect up a set to create a Facebook Custom Audience with,
 and then use the resultant Custom Audience to target ads.
 
 @param accessToken The access token to use to establish the user's identity for users logged into Facebook through this app.
 If `nil`, then the `[FBSDKAccessToken currentAccessToken]` is used.
 
 @discussion
 The JSON in the request's response will include an "custom_audience_third_party_id" key/value pair, with the value being the ID retrieved.
 This ID is an encrypted encoding of the Facebook user's ID and the invoking Facebook app ID.
 Multiple calls with the same user will return different IDs, thus these IDs cannot be used to correlate behavior
 across devices or applications, and are only meaningful when sent back to Facebook for creating Custom Audiences.
 
 The ID retrieved represents the Facebook user identified in the following way: if the specified access token is valid,
 the ID will represent the user associated with that token; otherwise the ID will represent the user logged into the
 native Facebook app on the device.  If there is no native Facebook app, no one is logged into it, or the user has opted out
 at the iOS level from ad tracking, then a `nil` ID will be returned.
 
 This method returns `nil` if either the user has opted-out (via iOS) from Ad Tracking, the app itself has limited event usage
 via the `[FBSDKSettings limitEventAndDataUsage]` flag, or a specific Facebook user cannot be identified.
 */
+ (YUNRequest *)requestForCustomAudienceThirdPartyIDWithAccessToken:(YUNAccessToken *)accessToken;

@end
