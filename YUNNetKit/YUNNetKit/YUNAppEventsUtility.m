//
//  YUNAppEventsUtility.m
//  YUNNetKit
//
//  Created by Orange on 5/23/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAppEventsUtility.h"

#import <AdSupport/AdSupport.h>

#import "YUNAccessToken.h"
#import "YUNAppEvents.h"
#import "YUNAppEventsDeviceInfo.h"
#import "YUNContants.h"
#import "YUNDynamicFrameworkLoader.h"
#import "YUNError.h"
#import "YUNInternalUtility.h"
#import "YUNLogger.h"
#import "YUNMacros.h"
#import "YUNSettings.h"
#import "YUNTimeSpentData.h"

#define YUN_APPEVENTSUTILITY_ANONYMOUSIDFILENAME @"com-facebook-sdk-PersistedAnonymousID.json"
#define YUN_APPEVENTSUTILITY_ANONYMOUSID_KEY @"anon_id"
#define YUN_APPEVENTSUTILITY_MAX_IDENTIFIER_LENGTH 40

@implementation YUNAppEventsUtility

+ (NSMutableDictionary *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                           implicitEventsOnly:(BOOL)implicitEventsOnly
                                     shouldAccessAdertisingID:(BOOL)shouldAccessAdvertisingID {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"event"] = eventCategory;
    
    NSString *attributionID = [[self class] attributionID]; // Only present on iOS 6 and below.
    [YUNInternalUtility dictionary:parameters setObject:attributionID forKey:@"attribution"];
    
    if (!implicitEventsOnly && shouldAccessAdvertisingID) {
        NSString *advertiserID = [[self class] advertiserID];
        [YUNInternalUtility dictionary:parameters setObject:advertiserID forKey:@"advertiser_id"];
    }
    
    parameters[YUN_APPEVENTSUTILITY_ANONYMOUSID_KEY] = [self anonymousID];
    
    YUNAdvertisingTrackingStatus advertisingTrackingStatus = [[self class] advertisingTrackingStatus];
    if (advertisingTrackingStatus != YUNAdvertisingTrackingUnspecified) {
        BOOL allowed = (advertisingTrackingStatus == YUNAdvertisingTrackingAllowed);
        parameters[@"advertiser_tracking_enabled"] = [@(allowed) stringValue];
    }
    
    parameters[@"application_tracking_enabled"] = [@(!YUNSettings.limitEventAndDataUsage) stringValue];
    
    [YUNAppEventsDeviceInfo extendDictionaryWithDeviceInfo:parameters];
    
    static dispatch_once_t fetchBundleOnce;
    static NSMutableArray *urlSchemes;
    
    dispatch_once(&fetchBundleOnce, ^{
        NSBundle *mainBundle = [NSBundle mainBundle];
        urlSchemes = [[NSMutableArray alloc] init];
        for (NSDictionary *fields in [mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"]) {
            NSArray *schemesForType = [fields objectForKey:@"CFBundleURLSchemes"];
            if (schemesForType) {
                [urlSchemes addObjectsFromArray:schemesForType];
            }
        }
    });
    
    if (urlSchemes.count > 0) {
        [parameters setObject:[YUNInternalUtility JSONStringForObject:urlSchemes error:NULL invalidObjectHandler:NULL] forKey:@"url_schemes"];
    }
    
    return parameters;
}

+ (NSString *)advertiserID
{
    NSString *result = nil;
    
    Class ASIdentifierManagerClass = yundfl_ASIdentifierManagerClass();
    if ([ASIdentifierManagerClass class]) {
        ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
        result = [[manager advertisingIdentifier] UUIDString];
    }
    
    return result;
}

+ (YUNAdvertisingTrackingStatus)advertisingTrackingStatus
{
    static dispatch_once_t fetchAdvertisingTrackingStatusOnce;
    static YUNAdvertisingTrackingStatus status;
    dispatch_once(&fetchAdvertisingTrackingStatusOnce, ^{
        status = YUNAdvertisingTrackingUnspecified;
        Class ASIdentifierManagerClass = yundfl_ASIdentifierManagerClass();
        if ([ASIdentifierManagerClass class]) {
            ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
            if (manager) {
                status = [manager isAdvertisingTrackingEnabled] ? YUNAdvertisingTrackingAllowed : YUNAdvertisingTrackingDisallowed;
            }
        }
    });
    
    return status;
}

+ (NSString *)anonymousID
{
    // Grab previously written anonymous ID and, if none have been generated, create and
    // persist a new one which will remain associated with this app.
    NSString *result = [[self class] retrievePersistedAnonymousID];
    if (!result) {
        // Generate a new anonymous ID. Create as a UUID, but then prepend the fairly
        // arbitrary 'XZ' to the front so it's easily distinguishable from IDFA's which
        // will only contain hex.
        result = [NSString stringWithFormat:@"XZ%@", [[NSUUID UUID] UUIDString]];
        
        [self persistAnonymousID:result];
    }
    return result;
}

+ (NSString *)attributionID
{
#if TARGET_OS_TV
    return nil;
#else
    return [[UIPasteboard pasteboardWithName:@"fb_app_attribution" create:NO] string];
#endif
}

// for tests only
+ (void)clearLibraryFiles
{
    [[NSFileManager defaultManager] removeItemAtPath:[[self class] persistenceFilePath:YUN_APPEVENTSUTILITY_ANONYMOUSIDFILENAME]
                                               error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[[self class] persistenceFilePath:YUNTimeSpentFilename]
                                               error:NULL];
}

+ (void)ensureOnMainThread:(NSString *)methodName className:(NSString *)className
{
    
}

+ (NSString *)flushReasonToString:(YUNAppEventsFlushReason)flushReason
{
    NSString *result = @"Unknown";
    switch (flushReason) {
        case YUNAppEventsFlushReasonExplicit:
            result = @"Explicit";
            break;
        case YUNAppEventsFlushReasonTimer:
            result = @"Timer";
            break;
        case YUNAppEventsFlushReasonSessionChange:
            result = @"SessionChange";
            break;
        case YUNAppEventsFlushReasonPersistedEvents:
            result = @"PersistedEvents";
            break;
        case YUNAppEventsFlushReasonEvnetThreshold:
            result = @"EventCountThreshold";
            break;
        case YUNAppEventsFlushReasonEagerlyFlushingEvent:
            result = @"EagerlyFlushingEvent";
            break;
    }
    return result;
}

+ (void)logAndNotify:(NSString *)msg
{
    [[self class] logAndNotify:msg allowLogAsDeveloperError:YES];
}

+ (void)logAndNotify:(NSString *)msg allowLogAsDeveloperError:(BOOL)allowLogAsDeveloperError
{
    NSString *behaviorToLog = YUNLoggingBehaviorAppEvents;
    if (allowLogAsDeveloperError) {
        if ([[YUNSettings loggingBehavior] containsObject:YUNLoggingBehaviorDeveloperErrors]) {
            // Rather than log twice, prefer 'DeveloperErrors' if it's set over AppEvents.
            behaviorToLog = YUNLoggingBehaviorDeveloperErrors;
        }
    }
    
    [YUNLogger singleShotLogEntry:behaviorToLog logEntry:msg];
    NSError *error = [YUNError errorWithCode:YUNAppEventsFlushErrorCode message:msg];
    [[NSNotificationCenter defaultCenter] postNotificationName:YUNAppEventsLoggingResultNotification object:error];
}

+ (BOOL)regexValidateIdentifier:(NSString *)identifier
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    static NSMutableSet *cachedIdentifiers;
    dispatch_once(&onceToken, ^{
        NSString *regexString = @"^[0-9a-zA-Z_]+[0-9a-zA-Z _-]*$";
        regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                          options:0
                                                            error:NULL];
        cachedIdentifiers = [[NSMutableSet alloc] init];
    });
    
    @synchronized(self) {
        if (![cachedIdentifiers containsObject:identifier]) {
            NSUInteger numMatches = [regex numberOfMatchesInString:identifier options:0 range:NSMakeRange(0, identifier.length)];
            if (numMatches > 0) {
                [cachedIdentifiers addObject:identifier];
            } else {
                return NO;
            }
        }
    }
    
    return YES;
}
+ (BOOL)validateIdentifier:(NSString *)identifier
{
    if (identifier == nil || identifier.length == 0 || identifier.length > YUN_APPEVENTSUTILITY_MAX_IDENTIFIER_LENGTH || ![[self class] regexValidateIdentifier:identifier]) {
        [[self class] logAndNotify:[NSString stringWithFormat:@"Invalid identifier: '%@'. Must be between 1 and %d characters, and must be contain only alphanumerics, _, - or spaces, starting with alphanumeric or _.", identifier, YUN_APPEVENTSUTILITY_MAX_IDENTIFIER_LENGTH]];
        return NO;
    }
    
    return YES;
}

+ (void)persistAnonymousID:(NSString *)anonymousID
{
    [[self class] ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass(self)];
    NSDictionary *data = @{YUN_APPEVENTSUTILITY_ANONYMOUSID_KEY : anonymousID};
    NSString *content = [YUNInternalUtility JSONStringForObject:data error:NULL invalidObjectHandler:NULL];
    
    [content writeToFile:[[self class] persistenceFilePath:YUN_APPEVENTSUTILITY_ANONYMOUSIDFILENAME]
              atomically:YES
                encoding:NSASCIIStringEncoding
                   error:nil];
}

+ (NSString *)persistenceFilePath:(NSString *)filename
{
    NSSearchPathDirectory directory = NSLibraryDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    return [docDirectory stringByAppendingString:filename];
}

+ (NSString *)retrievePersistedAnonymousID
{
    [[self class] ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass(self)];
    NSString *file = [[self class] persistenceFilePath:YUN_APPEVENTSUTILITY_ANONYMOUSIDFILENAME];
    NSString *content = [[NSString alloc] initWithContentsOfFile:file
                                                        encoding:NSASCIIStringEncoding
                                                           error:nil];
    NSDictionary *results = [YUNInternalUtility objectForJSONString:content error:NULL];
    return [results objectForKey:YUN_APPEVENTSUTILITY_ANONYMOUSID_KEY];
}

// Given a candidate token (which may be nil), find the real token to string to use.
// Precedence: 1) provided token, 2) current token, 3) app + client token, 4) fully anonymous session.
+ (NSString *)tokenStringToUseFor:(YUNAccessToken *)token
{
    if (!token) {
        token = [YUNAccessToken currentAccessToken];
    }
    
    NSString *appID = [YUNAppEvents loggingOverrideAppID] ?: token.appID ?: [YUNSettings appID];
    NSString *tokenString = token.tokenString;
    if (!tokenString || ![appID isEqualToString:token.appID]) {
        // If there's an logging override app id present, then we don't want to use the client token since the client token
        // is intended to match up with the primary app id (and AppEvents doesn't require a client token).
        NSString *clientTokenString = [YUNSettings clientToken];
        if (clientTokenString && appID && [appID isEqualToString:token.appID]) {
            tokenString = [NSString stringWithFormat:@"%@|%@", appID, clientTokenString];
        } else if (appID) {
            tokenString = nil;
        }
    }
    return tokenString;
}

+ (long)unixTimeNow
{
    return (long)round([[NSDate date] timeIntervalSince1970]);
}

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

@end
