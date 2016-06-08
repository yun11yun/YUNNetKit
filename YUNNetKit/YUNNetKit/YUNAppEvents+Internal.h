//
//  YUNAppEvents+Internal.h
//  YUNNetKit
//
//  Created by Orange on 5/23/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAppEvents.h"

#import "YUNMacros.h"

#import "YUNAppEventsUtility.h"

@class YUNRequest;

// Internally known event names

extern NSString *const YUNAppEventNamePurchased;

/*! Use to log that the share dialog was launched */
extern NSString *const YUNAppEventNameShareSheetLaunch;

/*! Use to log that the share dialog was dismissed */
extern NSString *const YUNAppEventNameShareSheetDismiss;

/*! Use to log that the permissions UI was launched */
extern NSString *const YUNAppEventNamePermissionsUILaunch;

/*! Use to log that the permissions UI was dismissed */
extern NSString *const YUNAppEventNamePermissionsUIDismiss;

/*! Use to log that the login view was used */
extern NSString *const YUNAppEventNameLoginViewUsage;

// Internally known event parameters

/*! String parameter specigying the outcome of a dialog invocation */
extern NSString *const YUNAppEventParameterDialogOutcome;

/*! Parameter key used to specify which application lauches this application. */
extern NSString *const YUNAppEventParameterLaunchSource;

/*! Use to log the result of a call to YUNDialogs presentShareDialogWithParams: */
extern NSString *const YUNAppEventNameYUNDialogsPresentShareDialog;

/*! Use to log the result of a call to YUNDialogs presentShareDialogWithOpenActionParams: */
extern NSString *const YUNAppEventNameYUNDialogsPresentShareDialogOG;

/*! Use to log the result of a call to YUNDialogs presentLikeDialogWithLikeParams: */
extern NSString *const YUNAppEventNameYUNDialogsPresentLikeDialogOG;

extern NSString *const YUNAppEventNameYUNDialogsPresentShareDialogPhoto;
extern NSString *const YUNAppEventNameYUNDialogsPresentMessageDialog;
extern NSString *const YUNAppEventNameYUNDialogsPresentMessageDialogPhoto;
extern NSString *const YUNAppEventNameYUNDialogsPresentMessageDialogOG;

/*! Use to log the start of an auth request that cannot be fulfilled by the token cache */
extern NSString *const YUNAppEventNameYUNSessionAuthStart;

/*! Use to log the end of an auth request that was not fulfilled by the token cache */
extern NSString *const YUNAppEventNameYUNSessionAuthEnd;

/*! Use to log the start of a specific auth method as part of an auth request */
extern NSString *const YUNAppEventNameYUNSessionAuthMethodStart;

/*! Use to log the end of the last of tried auth method as part of an auth request */
extern NSString *const YUNAppEventNameYUNSessionAuthMethodEnd;

/*! Use to log the timestamp for the transition to the native login dialog */
extern NSString *const YUNAppEventNameYUNDialogsNativeLoginDialogStart;

/*! Use to log the timestamp for the transition back to the app after the Facebook native login dialog */
extern NSString *const YUNAppEventNameFBDialogsNativeLoginDialogEnd;

/*! Use to log the e2e timestamp metrics for web login */
extern NSString *const YUNAppEventNameFBDialogsWebLoginCompleted;

/*! Use to log the results of a share dialog */
extern NSString *const YUNAppEventNameYUNEventShareDialogResult;
extern NSString *const YUNAppEventNameYUNEventMessengerShareDialogResult;
extern NSString *const YUNAppEventNameYUNEventAppInviteShareDialogResult;

extern NSString *const YUNAppEventNameYUNEventShareDialogShow;
extern NSString *const YUNAppEventNameYUNEventMessengerShareDialogShow;
extern NSString *const YUNAppEventNameYUNEventAppInviteShareDialogShow;

extern NSString *const YUNAppEventParameterDialogMode;
extern NSString *const YUNAppEventParameterDialogShareContentType;

// Internally known event parameter values

extern NSString *const YUNAppEventsDialogOutcomeValue_Completed;
extern NSString *const YUNAppEventsDialogOutcomeValue_Cancelled;
extern NSString *const YUNAppEventsDialogOutcomeValue_Failed;

extern NSString *const YUNAppEventsDialogShareContentTypeOpenGraph;
extern NSString *const YUNAppEventsDialogShareContentTypeStatus;
extern NSString *const YUNAppEventsDialogShareContentTypePhoto;
extern NSString *const YUNAppEventsDialogShareContentTypeVideo;
extern NSString *const YUNAppEventsDialogShareContentTypeUnknown;


extern NSString *const YUNAppEventsDialogShareModeAutomatic;
extern NSString *const YUNAppEventsDialogShareModeBrowser;
extern NSString *const YUNAppEventsDialogShareModeNative;
extern NSString *const YUNAppEventsDialogShareModeShareSheet;
extern NSString *const YUNAppEventsDialogShareModeWeb;
extern NSString *const YUNAppEventsDialogShareModeFeedBrowser;
extern NSString *const YUNAppEventsDialogShareModeFeedWeb;
extern NSString *const YUNAppEventsDialogShareModeUnknown;

extern NSString *const YUNAppEventsNativeLoginDialogStartTime;
extern NSString *const YUNAppEventsNativeLoginDialogEndTime;

extern NSString *const YUNAppEventsWebLoginE2E;

extern NSString *const YUNAppEventNameYUNLikeButtonImpression;
extern NSString *const YUNAppEventNameYUNLoginButtonImpression;
extern NSString *const YUNAppEventNameYUNSendButtonImpression;
extern NSString *const YUNAppEventNameYUNShareButtonImpression;

extern NSString *const YUNAppEventNameYUNLikeButtonDidTap;
extern NSString *const YUNAppEventNameYUNLoginButtonDidTap;
extern NSString *const YUNAppEventNameYUNSendButtonDidTap;
extern NSString *const YUNAppEventNameYUNShareButtonDidTap;

extern NSString *const YUNAppEventNameYUNLikeControlDidDisable;
extern NSString *const YUNAppEventNameYUNLikeControlDidLike;
extern NSString *const YUNAppEventNameYUNLikeControlDidPresentDialog;
extern NSString *const YUNAppEventNameYUNLikeControlDidTap;
extern NSString *const YUNAppEventNameYUNLikeControlDidUnlike;
extern NSString *const YUNAppEventNameYUNLikeControlError;
extern NSString *const YUNAppEventNameYUNLikeControlImpression;
extern NSString *const YUNAppEventNameYUNLikeControlNetworkUnavailable;

extern NSString *const YUNAppEventParameterDialogErrorMessage;

@interface YUNAppEvents (Internal)

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
             accessToken:(YUNAccessToken *)accessToken;

+ (YUNAppEvents *)singleton;
- (void)flushForReason:(YUNAppEventsFlushReason)flushReason;

@end
