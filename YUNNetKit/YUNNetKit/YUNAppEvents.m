//
//  YUNAppEvents.m
//  YUNNetKit
//
//  Created by Orange on 5/20/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAppEvents.h"
#import "YUNAppEvents+Internal.h"

#import <UIKit/UIApplication.h>

#import "YUNAccessToken.h"
#import "YUNAppEventsState.h"
#import "YUNAppEventsStateManager.h"
#import "YUNAppEventsUtility.h"
#import "YUNContants.h"
#import "YUNError.h"
#import "YUNRequest+Internal.h"
#import "YUNInternalUtility.h"
#import "YUNLogger.h"
#import "YUNPaymentObserver.h"
#import "YUNServerConfiguration.h"
#import "YUNServerConfigurationManager.h"
#import "YUNSettings.h"
#import "YUNTimeSpentData.h"
#import "YUNUtility.h"

//
// Public event names
//

// General purpose
NSString *const YUNAppEventNameCompletedRegistration   = @"fb_mobile_complete_registration";
NSString *const YUNAppEventNameViewedContent           = @"fb_mobile_content_view";
NSString *const YUNAppEventNameSearched                = @"fb_mobile_search";
NSString *const YUNAppEventNameRated                   = @"fb_mobile_rate";
NSString *const YUNAppEventNameCompletedTutorial       = @"fb_mobile_tutorial_completion";
NSString *const YUNAppEventParameterLaunchSource          = @"fb_mobile_launch_source";

// Ecommerce related
NSString *const YUNAppEventNameAddedToCart             = @"fb_mobile_add_to_cart";
NSString *const YUNAppEventNameAddedToWishlist         = @"fb_mobile_add_to_wishlist";
NSString *const YUNAppEventNameInitiatedCheckout       = @"fb_mobile_initiated_checkout";
NSString *const YUNAppEventNameAddedPaymentInfo        = @"fb_mobile_add_payment_info";

// Gaming related
NSString *const YUNAppEventNameAchievedLevel           = @"fb_mobile_level_achieved";
NSString *const YUNAppEventNameUnlockedAchievement     = @"fb_mobile_achievement_unlocked";
NSString *const YUNAppEventNameSpentCredits            = @"fb_mobile_spent_credits";

//
// Public event parameter names
//

NSString *const YUNAppEventParameterNameCurrency               = @"fb_currency";
NSString *const YUNAppEventParameterNameRegistrationMethod     = @"fb_registration_method";
NSString *const YUNAppEventParameterNameContentType            = @"fb_content_type";
NSString *const YUNAppEventParameterNameContentID              = @"fb_content_id";
NSString *const YUNAppEventParameterNameSearchString           = @"fb_search_string";
NSString *const YUNAppEventParameterNameSuccess                = @"fb_success";
NSString *const YUNAppEventParameterNameMaxRatingValue         = @"fb_max_rating_value";
NSString *const YUNAppEventParameterNamePaymentInfoAvailable   = @"fb_payment_info_available";
NSString *const YUNAppEventParameterNameNumItems               = @"fb_num_items";
NSString *const YUNAppEventParameterNameLevel                  = @"fb_level";
NSString *const YUNAppEventParameterNameDescription            = @"fb_description";

//
// Public event parameter values
//

NSString *const YUNAppEventParameterValueNo                    = @"0";
NSString *const YUNAppEventParameterValueYes                   = @"1";

//
// Event names internal to this file
//
NSString *const YUNAppEventNamePurchased        = @"fb_mobile_purchase";

NSString *const YUNAppEventNameLoginViewUsage                   = @"fb_login_view_usage";
NSString *const YUNAppEventNameShareSheetLaunch                 = @"fb_share_sheet_launch";
NSString *const YUNAppEventNameShareSheetDismiss                = @"fb_share_sheet_dismiss";
NSString *const YUNAppEventNamePermissionsUILaunch              = @"fb_permissions_ui_launch";
NSString *const YUNAppEventNamePermissionsUIDismiss             = @"fb_permissions_ui_dismiss";
NSString *const YUNAppEventNameYUNDialogsPresentShareDialog      = @"fb_dialogs_present_share";
NSString *const YUNAppEventNameYUNDialogsPresentShareDialogPhoto = @"fb_dialogs_present_share_photo";
NSString *const YUNAppEventNameYUNDialogsPresentShareDialogOG    = @"fb_dialogs_present_share_og";
NSString *const YUNAppEventNameYUNDialogsPresentLikeDialogOG     = @"fb_dialogs_present_like_og";
NSString *const YUNAppEventNameYUNDialogsPresentMessageDialog      = @"fb_dialogs_present_message";
NSString *const YUNAppEventNameYUNDialogsPresentMessageDialogPhoto = @"fb_dialogs_present_message_photo";
NSString *const YUNAppEventNameYUNDialogsPresentMessageDialogOG    = @"fb_dialogs_present_message_og";

NSString *const YUNAppEventNameYUNDialogsNativeLoginDialogStart  = @"fb_dialogs_native_login_dialog_start";
NSString *const YUNAppEventsNativeLoginDialogStartTime          = @"fb_native_login_dialog_start_time";

NSString *const YUNAppEventNameYUNDialogsNativeLoginDialogEnd    = @"fb_dialogs_native_login_dialog_end";
NSString *const YUNAppEventsNativeLoginDialogEndTime            = @"fb_native_login_dialog_end_time";

NSString *const YUNAppEventNameYUNDialogsWebLoginCompleted       = @"fb_dialogs_web_login_dialog_complete";
NSString *const YUNAppEventsWebLoginE2E                         = @"fb_web_login_e2e";

NSString *const YUNAppEventNameYUNSessionAuthStart               = @"fb_mobile_login_start";
NSString *const YUNAppEventNameYUNSessionAuthEnd                 = @"fb_mobile_login_complete";
NSString *const YUNAppEventNameYUNSessionAuthMethodStart         = @"fb_mobile_login_method_start";
NSString *const YUNAppEventNameYUNSessionAuthMethodEnd           = @"fb_mobile_login_method_complete";

NSString *const YUNAppEventNameYUNLikeButtonImpression        = @"fb_like_button_impression";
NSString *const YUNAppEventNameYUNLoginButtonImpression       = @"fb_login_button_impression";
NSString *const YUNAppEventNameYUNSendButtonImpression        = @"fb_send_button_impression";
NSString *const YUNAppEventNameYUNShareButtonImpression       = @"fb_share_button_impression";

NSString *const YUNAppEventNameYUNLikeButtonDidTap  = @"fb_like_button_did_tap";
NSString *const YUNAppEventNameYUNLoginButtonDidTap  = @"fb_login_button_did_tap";
NSString *const YUNAppEventNameYUNSendButtonDidTap  = @"fb_send_button_did_tap";
NSString *const YUNAppEventNameYUNShareButtonDidTap  = @"fb_share_button_did_tap";

NSString *const YUNAppEventNameLikeControlDidDisable          = @"fb_like_control_did_disable";
NSString *const YUNAppEventNameYUNLikeControlDidLike             = @"fb_like_control_did_like";
NSString *const YUNAppEventNameYUNLikeControlDidPresentDialog    = @"fb_like_control_did_present_dialog";
NSString *const YUNAppEventNameYUNLikeControlDidTap              = @"fb_like_control_did_tap";
NSString *const YUNAppEventNameYUNLikeControlDidUnlike           = @"fb_like_control_did_unlike";
NSString *const YUNAppEventNameYUNLikeControlError               = @"fb_like_control_error";
NSString *const YUNAppEventNameYUNLikeControlImpression          = @"fb_like_control_impression";
NSString *const YUNAppEventNameYUNLikeControlNetworkUnavailable  = @"fb_like_control_network_unavailable";

NSString *const YUNAppEventNameYUNEventShareDialogResult =              @"fb_dialog_share_result";
NSString *const YUNAppEventNameYUNEventMessengerShareDialogResult =     @"fb_messenger_dialog_share_result";
NSString *const YUNAppEventNameYUNEventAppInviteShareDialogResult =     @"fb_app_invite_dialog_share_result";

NSString *const YUNAppEventNameYUNEventShareDialogShow =            @"fb_dialog_share_show";
NSString *const YUNAppEventNameYUNEventMessengerShareDialogShow =   @"fb_messenger_dialog_share_show";
NSString *const YUNAppEventNameYUNEventAppInviteShareDialogShow =   @"fb_app_invite_share_show";

// Event Parameters internal to this file
NSString *const YUNAppEventParameterDialogOutcome               = @"fb_dialog_outcome";
NSString *const YUNAppEventParameterDialogErrorMessage          = @"fb_dialog_outcome_error_message";
NSString *const YUNAppEventParameterDialogMode                  = @"fb_dialog_mode";
NSString *const YUNAppEventParameterDialogShareContentType      = @"fb_dialog_share_content_type";

// Event parameter values internal to this file
NSString *const YUNAppEventsDialogOutcomeValue_Completed = @"Completed";
NSString *const YUNAppEventsDialogOutcomeValue_Cancelled = @"Cancelled";
NSString *const YUNAppEventsDialogOutcomeValue_Failed    = @"Failed";

NSString *const YUNAppEventsDialogShareModeAutomatic      = @"Automatic";
NSString *const YUNAppEventsDialogShareModeBrowser        = @"Browser";
NSString *const YUNAppEventsDialogShareModeNative         = @"Native";
NSString *const YUNAppEventsDialogShareModeShareSheet     = @"ShareSheet";
NSString *const YUNAppEventsDialogShareModeWeb            = @"Web";
NSString *const YUNAppEventsDialogShareModeFeedBrowser    = @"FeedBrowser";
NSString *const YUNAppEventsDialogShareModeFeedWeb        = @"FeedWeb";
NSString *const YUNAppEventsDialogShareModeUnknown        = @"Unknown";

NSString *const YUNAppEventsDialogShareContentTypeOpenGraph       = @"OpenGraph";
NSString *const YUNAppEventsDialogShareContentTypeStatus          = @"Status";
NSString *const YUNAppEventsDialogShareContentTypePhoto           = @"Photo";
NSString *const YUNAppEventsDialogShareContentTypeVideo           = @"Video";
NSString *const YUNAppEventsDialogShareContentTypeUnknown         = @"Unknown";

NSString *const YUNAppEventsLoggingResultNotification = @"com.facebook.sdk:FBSDKAppEventsLoggingResultNotification";

NSString *const YUNAppEventsOverrideAppIDBundleKey = @"FacebookLoggingOverrideAppID";

#define NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER 100
#define FLUSH_PERIOD_IN_SECONDS 15
#define APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD 60 * 60 * 24

static NSString *g_overrideAppID = nil;

@interface YUNAppEvents ()

@property (nonatomic, readwrite) YUNAppEventsFlushBehavior flushBehavior;

//for testing only.
@property (nonatomic, assign) BOOL disableTimer;

@end

@implementation YUNAppEvents
{
    BOOL _explicitEventsLoggedYet;
    NSTimer *_flushTimer;
    NSTimer *_attributionIDRecheckTimer;
    YUNServerConfiguration *_serverConfiguration;
    YUNAppEventsState *_appEventsState;
}

#pragma mark - Object Lifecycle

+ (void)initialize
{
    if (self == [YUNAppEvents class]) {
        g_overrideAppID = [[[NSBundle mainBundle] objectForInfoDictionaryKey:YUNAppEventsOverrideAppIDBundleKey] copy];
    }
}

- (YUNAppEvents *)init
{
    self = [super init];
    if (self) {
        _flushBehavior = YUNAppEventsFlushBehaviorAuto;
        _flushTimer = [NSTimer timerWithTimeInterval:FLUSH_PERIOD_IN_SECONDS
                                              target:self
                                            selector:@selector(flushTimerFired:)
                                            userInfo:nil
                                             repeats:YES];
        _attributionIDRecheckTimer = [NSTimer timerWithTimeInterval:APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD
                                                             target:self
                                                           selector:@selector(appSettingsFetchStateResetTimerFired:)
                                                           userInfo:nil
                                                            repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_flushTimer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop mainRunLoop] addTimer:_attributionIDRecheckTimer forMode:NSDefaultRunLoopMode];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationMovingFromActiveStateOrTerminating)
         name:UIApplicationWillResignActiveNotification
         object:NULL];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationMovingFromActiveStateOrTerminating)
         name:UIApplicationWillTerminateNotification
         object:NULL];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationDidBecomeActive)
         name:UIApplicationDidBecomeActiveNotification
         object:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // tichnically these timers retain self so there's a cycle but
    // we're a singleton anyway.
    [_flushTimer invalidate];
    [_attributionIDRecheckTimer invalidate];
}

#pragma mark - Public methods

+ (void)logEvent:(NSString *)eventName
{
    [YUNAppEvents logEvent:eventName
                parameters:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
{
    [YUNAppEvents logEvent:eventName
                valueToSum:valueToSum
                parameters:nil];
}

+ (void)logEvent:(NSString *)eventName parameters:(NSDictionary *)parameters
{
    [YUNAppEvents logEvent:eventName
                valueToSum:nil
                parameters:parameters
               accessToken:nil];
}

+ (void)logEvent:(NSString *)eventName valueToSum:(double)valueToSum parameters:(NSDictionary *)parameters
{
    [YUNAppEvents logEvent:eventName
                valueToSum:[NSNumber numberWithDouble:valueToSum]
                parameters:parameters
               accessToken:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(NSNumber *)valueToSum
      parameters:(NSDictionary *)parameters
     accessToken:(YUNAccessToken *)accessToken
{
    [[YUNAppEvents singleton] instanceLogEvent:eventName
                                   valueToSum:valueToSum
                                   parameters:parameters
                           isImplicitlyLogged:NO
                                  accessToken:accessToken];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
{
    [YUNAppEvents logPurchase:purchaseAmount
                     currency:currency
                   parameters:nil];
}

+  (void)logPurchase:(double)purchaseAmount
            currency:(NSString *)currency
          parameters:(NSDictionary *)parameters
{
    [YUNAppEvents logPurchase:purchaseAmount
                     currency:currency
                   parameters:parameters
                  accessToken:nil];
}

+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency parameters:(NSDictionary *)parameters accessToken:(YUNAccessToken *)accessToken
{
    
    // A purchase event is just a regular logged event with a given event name
    // and treating the currency value a going into the parameters dictionary.
    NSDictionary *newParameters;
    if (!parameters) {
        newParameters = @{YUNAppEventParameterNameCurrency : currency};
    } else {
        newParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [newParameters setValue:currency forKey:YUNAppEventParameterNameCurrency];
    }
    
    [YUNAppEvents logEvent:YUNAppEventNamePurchased
                valueToSum:[NSNumber numberWithDouble:purchaseAmount]
                parameters:newParameters
               accessToken:accessToken];
    
    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since purchase events
    // are relavitely rare and relatively high value and worth getting across on wire right away.
    if ([YUNAppEvents flushBehavior] != YUNAppEventsFlushBehaviorExplicitOnly) {
        [[YUNAppEvents singleton] flushForReason:YUNAppEventsFlushReasonEagerlyFlushingEvent];
    }
}

+ (void)activateApp
{
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass(self)];
    
    // Fetch app settings and register for transaction notifications only if app supports implicit purchase events
    YUNAppEvents *instance = [YUNAppEvents singleton];
    [instance publishInstall];
    [instance fetchServerConfiguration:NULL];
    
    // Restore time spent data, indicating that we're being called from "activateApp", which will,
    // when appropriate, result in logging an "activated app" and "deactivate app" (for the
    // previous session) App Event.
    [YUNTimeSpentData restore:YES];
    
}

+ (YUNAppEventsFlushBehavior)flushBehavior
{
    return [YUNAppEvents singleton].flushBehavior;
}

+ (void)setFlushBehavior:(YUNAppEventsFlushBehavior)flushBehavior
{
    [YUNAppEvents singleton].flushBehavior = flushBehavior;
}

+ (NSString *)loggingOverrideAppID
{
    return g_overrideAppID;
}

+ (void)setLoggingOverrideAppID:(NSString *)appID
{
    if (![g_overrideAppID isEqualToString:appID]) {
        
    }
}

+ (void)flush
{
    [[YUNAppEvents singleton] flushForReason:YUNAppEventsFlushReasonExplicit];
}

#pragma mark - Internal methods

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
             accessToken:(YUNAccessToken *)accessToken
{
    [[YUNAppEvents singleton] instanceLogEvent:eventName
                                   valueToSum:valueToSum
                                   parameters:parameters
                           isImplicitlyLogged:YES
                                  accessToken:accessToken];
}

+ (YUNAppEvents *)singleton
{
    static dispatch_once_t pred;
    static YUNAppEvents *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[YUNAppEvents alloc] init];
    });
    return shared;
}

- (void)flushForReason:(YUNAppEventsFlushReason)flushReason
{
    // Always flush asynchronously, even on main thread, for two reasons:
    // - most consistent code path for all threads.
    // - allow locks being held by caller to be released prior to actual flushing work being done.
    @synchronized(self) {
        if (!_appEventsState) {
            return;
        }
        YUNAppEventsState *copy = [_appEventsState copy];
        _appEventsState = [[YUNAppEventsState alloc] initWithToken:copy.tokenString appID:copy.appID];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self flushOnMainQueue:copy forReason:flushReason];
        });
    }
}

#pragma mark - Private methods

- (NSString *)appID
{
    return [YUNAppEvents loggingOverrideAppID] ?: [YUNSettings appID];
}

- (void)publishInstall
{
    NSString *appID = [self appID];
    NSString *lastAttributionPingString = [NSString stringWithFormat:@"com.yun11yun:lastAttributionPing%@", appID];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:lastAttributionPingString]) {
        return;
    }
    [self fetchServerConfiguration:^{
        NSDictionary *params = [YUNAppEventsUtility activityParametersDictionaryForEvent:@"MOBILE_APP_INSTALL"
                                                                      implicitEventsOnly:NO
                                                                shouldAccessAdertisingID:_serverConfiguration.isAdvertisingIDEnabled];
        NSString *path = [NSString stringWithFormat:@"%@/avtivities", appID];
        YUNRequest *request = [[YUNRequest alloc] initWithPath:path
                                                    parameters:params
                                                   tokenString:nil
                                                    HTTPMethod:@"POST"
                                                         flags:YUNRequestFlagDoNotInvalidateTokenOnError | YUNRequestFlagDisableErrorRecovery];
        [request startWithCompletionHandler:^(YUNRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [defaults setObject:[NSDate date] forKey:lastAttributionPingString];
                NSString *lastInstallResponseKey = [NSString stringWithFormat:@"com.yun11yun:lastInstallResponse%@", appID];
                [defaults setObject:result forKey:lastInstallResponseKey];
                [defaults synchronize];
            }
        }];
    }];
}

// app events can use a server  configuration up to 24 hours old to minimize network traffic.
- (void)fetchServerConfiguration:(void (^)(void))callback
{
    if (_serverConfiguration == nil) {
        [YUNServerConfigurationManager loadServerConfigurationWithCompletionBlock:^(YUNServerConfiguration *serverConfiguration, NSError *error) {
            _serverConfiguration = serverConfiguration;
            
            if (_serverConfiguration.implicitPurchaseLoggingEnabled) {
                [YUNPaymentObserver startObservingTransactions];
            } else {
                [YUNPaymentObserver stopObservingTransactions];
            }
            if (callback) {
                callback();
            }
        }];
        return;
    }
    if (callback) {
        callback();
    }
}

- (void)instanceLogEvent:(NSString *)eventName
             valueToSum:(NSNumber *)valueToSum
             parameters:(NSDictionary *)parameters
     isImplicitlyLogged:(BOOL)isImplicitlyLogged
            accessToken:(YUNAccessToken *)accessToken
{
    if (isImplicitlyLogged && _serverConfiguration && !_serverConfiguration.isImplicitLoggingSupported) {
        return;
    }
    
    if (isImplicitlyLogged && !_explicitEventsLoggedYet) {
        _explicitEventsLoggedYet = YES;
    }
    
    __block BOOL failed = NO;
    
    if (![YUNAppEventsUtility validateIdentifier:eventName]) {
        failed = YES;
    }
    
    // Make sure parameter dictionary is well formed. Log and exit if not.
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]]) {
            [YUNAppEventsUtility logAndNotify:[NSString stringWithFormat:@"The keys in the parameters must be NSStrings, '%@' is not.", key]];
            failed = YES;
        }
        if (![YUNAppEventsUtility validateIdentifier:key]) {
            failed = YES;
        }
        if (![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[NSNumber class]]) {
            [YUNAppEventsUtility logAndNotify:[NSString stringWithFormat:@"The values in the parameters dictionary must be NSStrings or NSNumbers, '%@' is not.", obj]];
            failed = YES;
        }
    }];
    
    if (failed) {
        return;
    }
    
    NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
    eventDictionary[@"_eventName"] = eventName;
    eventDictionary[@"_logTime"] = @([YUNAppEventsUtility unixTimeNow]);
    [YUNInternalUtility dictionary:eventDictionary setObject:valueToSum forKey:@"_valueToSum"];
    if (isImplicitlyLogged) {
        eventDictionary[@"_implicitlyLogged"] = @"1";
    }
    
    NSString *currentViewControllerName;
    if ([NSThread isMainThread]) {
        // We only collect the view controller when on the main thread, as the behavior off
        // the main thread is unpredictable.  Besides, UI state for off-main-thread computations
        // isn't really relevant anyhow.
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
        if (vc) {
            currentViewControllerName = [[vc class] description];
        } else {
            currentViewControllerName = @"no_ui";
        }
    } else {
        currentViewControllerName = @"off_thread";
    }
    eventDictionary[@"_ui"] = currentViewControllerName;
    
    NSString *tokenString = [YUNAppEventsUtility tokenStringToUseFor:accessToken];
    NSString *appID = [self appID];
    
    @synchronized(self) {
        if (!_appEventsState) {
            _appEventsState = [[YUNAppEventsState alloc] initWithToken:tokenString appID:appID];
        } else if (![_appEventsState isCompatibleWithTokenString:tokenString appID:appID]) {
            if (self.flushBehavior == YUNAppEventsFlushBehaviorExplicitOnly) {
                [YUNAppEventsStateManager persistAppEventsData:_appEventsState];
            } else {
                [self flushForReason:YUNAppEventsFlushReasonSessionChange];
            }
            _appEventsState = [[YUNAppEventsState alloc] initWithToken:tokenString appID:appID];
        }
        
        [_appEventsState addEvent:eventDictionary isImplicit:isImplicitlyLogged];
        if (!isImplicitlyLogged) {
            [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                             formatString:@"YUNAppEvents: Recording event @%ld: %@",
             [YUNAppEventsUtility unixTimeNow],
             eventDictionary];
        }
        
        [self checkPersistedEvents];
        
        if (_appEventsState.events.count > NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER &&
            self.flushBehavior != YUNAppEventsFlushBehaviorExplicitOnly) {
            [self flushForReason:YUNAppEventsFlushReasonEvnetThreshold];
        }
    }
}

// this fetches persisted event states.
// for those matching the currently tracked events, add it.
// otherwise, either flush (if not explicitonly behavior) or persist them back.
- (void)checkPersistedEvents
{
    NSArray *existingEventsStates = [YUNAppEventsStateManager retrievePersistedAppEventsStates];
    if (existingEventsStates.count == 0) {
        return;
    }
    
    YUNAppEventsState *matchingEventsPreviouslySaved = nil;
    // reduce lock time by creating a new YUNAppEventsState tp collect matching persisted events.
    @synchronized(self) {
        if (_appEventsState) {
            matchingEventsPreviouslySaved = [[YUNAppEventsState alloc] initWithToken:_appEventsState.tokenString appID:_appEventsState.appID];
        }
    }
    for (YUNAppEventsState *saved in existingEventsStates) {
        if ([saved isCompatibleWithAppEvnetsState:matchingEventsPreviouslySaved]) {
            [matchingEventsPreviouslySaved addEventsFromAppEventState:saved];
        } else {
            if (self.flushBehavior == YUNAppEventsFlushBehaviorExplicitOnly) {
                [YUNAppEventsStateManager persistAppEventsData:saved];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self flushOnMainQueue:saved forReason:YUNAppEventsFlushReasonPersistedEvents];
                });
            }
        }
    }
    if (matchingEventsPreviouslySaved.events.count > 0) {
        @synchronized(self) {
            if ([_appEventsState isCompatibleWithAppEvnetsState:matchingEventsPreviouslySaved]) {
                [_appEventsState addEventsFromAppEventState:matchingEventsPreviouslySaved];
            }
        }
    }
}

- (void)flushOnMainQueue:(YUNAppEventsState *)appEventsState
               forReason:(YUNAppEventsFlushReason)reason
{
    if (appEventsState.events.count == 0) {
        return;
    }
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
    
    [self fetchServerConfiguration:^(void){
        NSString *JSONString = [appEventsState JSONStringForEvents:_serverConfiguration.implicitLoggingEnabled];
        NSData *encodedEvents = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
        if (!encodedEvents) {
            [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                                 logEntry:@"YUNAppEvents: Flushing skipped - no events after removing implicitly logged ones.\n"];
            return ;
        }
        NSMutableDictionary *postParameters = [YUNAppEventsUtility activityParametersDictionaryForEvent:@"CUSTOM_APP_EVENTS" implicitEventsOnly:appEventsState.areAllEventsImplicit shouldAccessAdertisingID:_serverConfiguration.advertisingIDEnabled];
        postParameters[@"custom_events_file"] = encodedEvents;
        if (appEventsState.numSkipped > 0) {
            postParameters[@"num_skipped_events"] = [NSString stringWithFormat:@"%lu", (unsigned long)appEventsState.numSkipped];
        }
        
        NSString *loggingEntry = nil;
        if ([[YUNSettings loggingBehavior] containsObject:YUNLoggingBehaviorAppEvents]) {
            NSData *prettyJSONData = [NSJSONSerialization dataWithJSONObject:appEventsState.events options:NSJSONWritingPrettyPrinted error:NULL];
            NSString *prettyPrintedJsonEvents = [[NSString alloc] initWithData:prettyJSONData encoding:NSUTF8StringEncoding];
            
            // Remove this param -- just an encoding of the events which we pretty print later.
            NSMutableDictionary *paramsForPrinting = [postParameters mutableCopy];
            [paramsForPrinting removeObjectForKey:@"custom_events_file"];
            
            loggingEntry = [NSString stringWithFormat:@"YUNAppEvents: Flushed %ld, %lu events due to '%@' - %@\nEvents: %@",
                            [YUNAppEventsUtility unixTimeNow],
                            (unsigned long)appEventsState.events.count,
                            [YUNAppEventsUtility flushReasonToString:reason],
                            paramsForPrinting,
                            prettyPrintedJsonEvents];
        }
        
        YUNRequest *request = [[YUNRequest alloc] initWithPath:[NSString stringWithFormat:@"%@/activities", appEventsState.appID]
                                                    parameters:postParameters
                                                   tokenString:appEventsState.tokenString
                                                    HTTPMethod:@"POST"
                                                         flags:YUNRequestFlagDoNotInvalidateTokenOnError | YUNRequestFlagDisableErrorRecovery];
        
        [request startWithCompletionHandler:^(YUNRequestConnection *connection, id result, NSError *error) {
            [self handleActivitiesPostCompletion:error
                                    loggingEntry:loggingEntry
                                  appEventsState:(YUNAppEventsState *)appEventsState];
        }];
    }];
}

- (void)handleActivitiesPostCompletion:(NSError *)error
                          loggingEntry:(NSString *)loggingEntry
                        appEventsState:(YUNAppEventsState *)appEventsState
{
    typedef NS_ENUM(NSUInteger, FBSDKAppEventsFlushResult) {
        FlushResultSuccess,
        FlushResultServerError,
        FlushResultNoConnectivity
    };
    
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
    
    FBSDKAppEventsFlushResult flushResult = FlushResultSuccess;
    if (error) {
        NSInteger errorCode = [error.userInfo[YUNRequestErrorHTTPStatusCodeKey] integerValue];
        
        // We interpret a 400 coming back from FBRequestConnection as a server error due to improper data being
        // sent down.  Otherwise we assume no connectivity, or another condition where we could treat it as no connectivity.
        flushResult = errorCode == 400 ? FlushResultServerError : FlushResultNoConnectivity;
    }
    
    if (flushResult == FlushResultServerError) {
        // Only log events that developer can do something with (i.e., if parameters are incorrect).
        //  as opposed to cases where the token is bad.
        if ([error.userInfo[YUNRequestErrorCategoryKey] unsignedIntegerValue] == YUNRequestErrorCategoryOther) {
            NSString *message = [NSString stringWithFormat:@"Failed to send AppEvents: %@", error];
            [YUNAppEventsUtility logAndNotify:message allowLogAsDeveloperError:!appEventsState.areAllEventsImplicit];
        }
    } else if (flushResult == FlushResultNoConnectivity) {
        @synchronized(self) {
            if ([appEventsState isCompatibleWithAppEvnetsState:_appEventsState]) {
                [_appEventsState addEventsFromAppEventState:appEventsState];
            } else {
                // flush failed due to connectivity. Persist to be tried again later.
                [YUNAppEventsStateManager persistAppEventsData:appEventsState];
            }
        }
    }
    
    NSString *resultString = @"<unknown>";
    switch (flushResult) {
        case FlushResultSuccess:
            resultString = @"Success";
            break;
            
        case FlushResultNoConnectivity:
            resultString = @"No Connectivity";
            break;
            
        case FlushResultServerError:
            resultString = [NSString stringWithFormat:@"Server Error - %@", [error description]];
            break;
    }
    
    [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                       formatString:@"%@\nFlush Result : %@", loggingEntry, resultString];
}

- (void)flushTimerFired:(id)arg
{
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
    if (self.flushBehavior != YUNAppEventsFlushBehaviorExplicitOnly && !self.disableTimer) {
        [self flushForReason:YUNAppEventsFlushReasonTimer];
    }
}

- (void)appSettingsFetchStateResetTimerFired:(id)arg
{
    _serverConfiguration = nil;
}

- (void)applicationDidBecomeActive
{
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
    
    [self checkPersistedEvents];
    
    // Restore time spent data, indicating that we're not being called from "activateApp".
    [YUNTimeSpentData restore:NO];
}

- (void)applicationMovingFromActiveStateOrTerminating
{
    // When moving from active state, we don't have time to wait for the result of a flush, so
    // just persist events to storage, and we'll process them at the next activation.
    YUNAppEventsState *copy = nil;
    @synchronized (self) {
        copy = [_appEventsState copy];
        _appEventsState = nil;
    }
    if (copy) {
        [YUNAppEventsStateManager persistAppEventsData:copy];
    }
    [YUNTimeSpentData suspend];
}

#pragma mark - Custom Audience

+ (YUNRequest *)requestForCustomAudienceThirdPartyIDWithAccessToken:(YUNAccessToken *)accessToken
{
    accessToken = accessToken ?: [YUNAccessToken currentAccessToken];
    // Rules for how we use the attribution ID / advertiser ID for an 'custom_audience_third_party_id' Graph API request
    // 1) if the OS tells us that the user has Limited Ad Tracking, then just don't send, and return a nil in the token.
    // 2) if the app has set 'limitEventAndDataUsage', this effectively implies that app-initiated ad targeting shouldn't happen,
    //    so use that data here to return nil as well.
    // 3) if we have a user session token, then no need to send attribution ID / advertiser ID back as the udid parameter
    // 4) otherwise, send back the udid parameter.
    
    if ([YUNAppEventsUtility advertisingTrackingStatus] == YUNAdvertisingTrackingDisallowed || [YUNSettings limitEventAndDataUsage]) {
        return nil;
    }
    
    NSString *tokenString = [YUNAppEventsUtility tokenStringToUseFor:accessToken];
    NSString *udid = nil;
    if (!accessToken) {
        // We don't have a logged in user, so we need some form of udid representation.  Prefer advertiser ID if
        // available, and back off to attribution ID if not.  Note that this function only makes sense to be
        // called in the context of advertising.
        udid = [YUNAppEventsUtility advertiserID];
        if (!udid) {
            udid = [YUNAppEventsUtility attributionID];
        }
        
        if (!udid) {
            // No udid, and no user token.  No point in making the request.
            return nil;
        }
    }
    
    NSDictionary *parameters = nil;
    if (udid) {
        parameters = @{ @"udid" : udid };
    }
    
    NSString *graphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", [[self singleton] appID]];
    YUNRequest *request = [[YUNRequest alloc] initWithPath:graphPath
                                                                   parameters:parameters
                                                                  tokenString:tokenString
                                                                   HTTPMethod:nil
                                                                        flags:YUNRequestFlagDoNotInvalidateTokenOnError | YUNRequestFlagDisableErrorRecovery];
    
    return request;
}

@end
