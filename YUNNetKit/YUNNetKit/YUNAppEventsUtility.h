//
//  YUNAppEventsUtility.h
//  YUNNetKit
//
//  Created by Orange on 5/23/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YUNAccessToken;

typedef NS_ENUM(NSUInteger, YUNAdvertisingTrackingStatus)
{
    YUNAdvertisingTrackingAllowed,
    YUNAdvertisingTrackingDisallowed,
    YUNAdvertisingTrackingUnspecified,
};

typedef NS_ENUM(NSUInteger, YUNAppEventsFlushReason)
{
    YUNAppEventsFlushReasonExplicit,
    YUNAppEventsFlushReasonTimer,
    YUNAppEventsFlushReasonSessionChange,
    YUNAppEventsFlushReasonPersistedEvents,
    YUNAppEventsFlushReasonEvnetThreshold,
    YUNAppEventsFlushReasonEagerlyFlushingEvent,
};

@interface YUNAppEventsUtility : NSObject

+ (NSMutableDictionary *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                           implicitEventsOnly:(BOOL)implicitEventsOnly
                                     shouldAccessAdertisingID:(BOOL)shouldAccessAdvertisingID;
+ (NSString *)advertiserID;
+ (YUNAdvertisingTrackingStatus)advertisingTrackingStatus;
+ (NSString *)attributionID;
+ (void)ensureOnMainThread:(NSString *)methodName className:(NSString *)className;
+ (NSString *)flushReasonToString:(YUNAppEventsFlushReason)flushReason;
+ (void)logAndNotify:(NSString *)msg allowLogAsDeveloperError:(BOOL)allowLogAsDeveloperError;
+ (void)logAndNotify:(NSString *)msg;
+ (NSString *)persistenceFilePath:(NSString *)filename;
+ (NSString *)tokenStringToUseFor:(YUNAccessToken *)token;
+ (long)unixTimeNow;
+ (BOOL)validateIdentifier:(NSString *)identifier;

@end
