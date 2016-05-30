//
//  YUNTimeSpentData.m
//  YUNNetKit
//
//  Created by Orange on 5/27/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNTimeSpentData.h"

#import "YUNAppEvents+Internal.h"
#import "YUNAppEventsUtility.h"
#import "YUNInternalUtility.h"
#import "YUNLogger.h"
#import "YUNSettings.h"

NSString *const YUNTimeSpentFilename = @"com-yun11yun-AppEventsTimeSpent.json";
static NSString *const YUNTimeSpentPersistKeySessionSecondsSpent = @"secondsSpentInCurrentSession";
static NSString *const YUNTimeSpentPersistKeySessionNumInterruptions = @"numInterruptions";
static NSString *const YUNTimeSpentPersistKeyLastSuspendTime = @"lastSuspendTime";

static NSString *const YUNAppEventNameActivatedApp = @"yun_mobile_activate_app";
static NSString *const YUNAppEventNameDeativatedApp = @"yun_mobile_deactivate_app";
static NSString *const YUNAppEventParameterNameSessionInterruptions = @"yun_moblie_app_interruptions";
static NSString *const YUNAppEventParameterNameTimeBetweenSessions = @"yun_mobile_time_between_sessions";

static const int NUM_SECONDS_IDLE_TO_BE_NEW_SESSION = 60;
static const int SECS_PER_MIN                       = 60;
static const int SECS_PER_HOUR                      = 60 * SECS_PER_MIN;
static const int SECS_PER_DAY                       = 24 * SECS_PER_HOUR;

static NSString *g_sourceApplication;
static BOOL g_isOpenedFromAppLink;

// Will be translated and displayed in App Insights.  Need to maintain same number and value of quanta on the server.
static const long INACTIVE_SECONDS_QUANTA[] =
{
    5 * SECS_PER_MIN,
    15 * SECS_PER_MIN,
    30 * SECS_PER_MIN,
    1 * SECS_PER_HOUR,
    6 * SECS_PER_HOUR,
    12 * SECS_PER_HOUR,
    1 * SECS_PER_DAY,
    2 * SECS_PER_DAY,
    3 * SECS_PER_DAY,
    7 * SECS_PER_DAY,
    14 * SECS_PER_DAY,
    21 * SECS_PER_DAY,
    28 * SECS_PER_DAY,
    60 * SECS_PER_DAY,
    90 * SECS_PER_DAY,
    120 * SECS_PER_DAY,
    150 * SECS_PER_DAY,
    180 * SECS_PER_DAY,
    365 * SECS_PER_DAY,
    LONG_MAX,   // keep as LONG_MAX to guarantee loop will terminate
};

/**
 * This class encapsulates the notion of an app 'session' - the length of time that the user has
 * spent in the app that can be considered a single usage of the app.  Apps may be frequently interrupted
 * do to other device activity, like a text message, so this class allows those interruptions to be smoothed
 * out and the time actually spent in the app excluding this interruption time to be accumulated.  Also,
 * once a certain amount of time has gone by where the app is not in the foreground, we consider the
 * session to be complete, and a new session beginning.  When this occurs, we log an 'activate app' event
 * with the duration of the previous session as the 'value' of this event, along with the number of
 * interruptions from that previous session as an event parameter.
 */
@interface YUNTimeSpentData ()

@property (nonatomic) NSInteger numSecondsIdleToBeNewSession;

@end

@implementation YUNTimeSpentData
{
    BOOL _isCurrentlyLoaded;
    BOOL _shouldLogActivateEvent;
    BOOL _shouldLogDeactivateEvent;
    long _secondsSpentInCurrentSession;
    long _timeSinceLastSuspend;
    int _numInterruptionsInCurrentSession;
    long _lastRestoreTime;
}

#pragma mark - Public methods

+ (void)suspend
{
    [self.singleton instanceSuspend];
}

+ (void)restore:(BOOL)calledFromActivateApp
{
    [self.singleton instanceRestore:calledFromActivateApp];
}

#pragma mark - Internal methods

- (instancetype)init
{
    if (self = [super init]) {
        _numSecondsIdleToBeNewSession = NUM_SECONDS_IDLE_TO_BE_NEW_SESSION;
    }
    return self;
}

+ (YUNTimeSpentData *)singleton
{
    static YUNTimeSpentData *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[YUNTimeSpentData alloc] init];
    });
    return shared;
}

// Calculate and persist time spent data for this instance of the app activation.
- (void)instanceSuspend
{
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
    if (!_isCurrentlyLoaded) {
        
        return;
    }
    
    long now = [YUNAppEventsUtility unixTimeNow];
    long timeSinceRestore = now - _lastRestoreTime;
    
    // Can happen if the clock on the device is changed
    if (timeSinceRestore < 0) {
        [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                           formatString:@"Clock skew detected"];
        timeSinceRestore = 0;
    }
    
    _secondsSpentInCurrentSession += timeSinceRestore;
    
    NSDictionary *timeSpentData =
    @{
      YUNTimeSpentPersistKeySessionSecondsSpent : @(_secondsSpentInCurrentSession),
      YUNTimeSpentPersistKeySessionNumInterruptions : @(_numInterruptionsInCurrentSession),
      YUNTimeSpentPersistKeyLastSuspendTime : @(now)
      };
    
    NSString *content = [YUNInternalUtility JSONStringForObject:timeSpentData error:NULL invalidObjectHandler:NULL];
    
    [content writeToFile:[YUNAppEventsUtility persistenceFilePath:YUNTimeSpentFilename]
              atomically:YES
                encoding:NSASCIIStringEncoding
                   error:nil];
    
    [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                       formatString:@"FBSDKTimeSpentData Persist: %@", content];
    
    _isCurrentlyLoaded = NO;
}

// Called during activation - either through an explicit 'activaateApp' call or implicitly when the app is foregrounded.
// In both cases, we restore the persisted event data. In the case of the activateAp, we log an 'app activated'
// event if there's been enough time between the last deactivaation and now.
- (void)instanceRestore:(BOOL)calledFromActivateApp
{
    [YUNAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
    
    // It's possible to call this multiple times during the time the app is in the foreground. If this is the case,
    // just restore persisted data the first time.
    if (!_isCurrentlyLoaded) {
        
        NSString *content = [[NSString alloc] initWithContentsOfFile:[YUNAppEventsUtility persistenceFilePath:YUNTimeSpentFilename]
                                                        usedEncoding:nil
                                                               error:nil];
        
        [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                         formatString:@"YUNTimeSpentData Restore: %@", content];
        
        long now = [YUNAppEventsUtility unixTimeNow];
        if (!content) {
            
            // Nothing persisted, so this is the first launch.
            _secondsSpentInCurrentSession = 0;
            _numInterruptionsInCurrentSession = 0;
            
            // We want to log the app activation event on the first launch, but not the deactivate event
            _shouldLogActivateEvent = YES;
            _shouldLogDeactivateEvent = NO;
        } else {
            
            NSDictionary *results = [YUNInternalUtility objectForJSONString:content error:NULL];
            
            long lastActiveTime = [[results objectForKey:YUNTimeSpentPersistKeyLastSuspendTime] longValue];
            
            _timeSinceLastSuspend = now - lastActiveTime;
            _secondsSpentInCurrentSession = [[results objectForKey:YUNTimeSpentPersistKeySessionSecondsSpent] intValue];
            _numInterruptionsInCurrentSession = [[results objectForKey:YUNTimeSpentPersistKeySessionNumInterruptions] intValue];
            _shouldLogDeactivateEvent = (_timeSinceLastSuspend > _numSecondsIdleToBeNewSession);
            
            // Other than the first launch, always log the last session's deactivate with this session's activate.
            _shouldLogDeactivateEvent = _shouldLogActivateEvent;
            
            if (!_shouldLogDeactivateEvent) {
                // If we're not logging, then the time we spent deactivate is considered another interruption. But cap it
                // so errant or test uses doesn't blow out the cardinality on the backend processing
                _numInterruptionsInCurrentSession = MIN(_numInterruptionsInCurrentSession + 1, 200);
            }
        }
        
        _lastRestoreTime = now;
        _isCurrentlyLoaded = YES;
        
        if (calledFromActivateApp) {
            
            if (_shouldLogDeactivateEvent) {
                [YUNAppEvents logEvent:YUNAppEventNameActivatedApp
                            parameters:@{
                                         YUNAppEventParameterLaunchSource : [[self class] getSourceApplication]
                                         }];
            }
            
            if (_shouldLogDeactivateEvent) {
                
                int quantaIndex = 0;
                while (_timeSinceLastSuspend > INACTIVE_SECONDS_QUANTA[quantaIndex]) {
                    quantaIndex++;
                }
                
                [YUNAppEvents logEvent:YUNAppEventNameDeativatedApp
                            valueToSum:_secondsSpentInCurrentSession
                            parameters:@{ YUNAppEventParameterNameSessionInterruptions : @(_numInterruptionsInCurrentSession),
                                          YUNAppEventParameterNameTimeBetweenSessions : [NSString stringWithFormat:@"session_quanta_%d", quantaIndex],
                                          YUNAppEventParameterLaunchSource: [[self class] getSourceApplication],
                                          }];
                
                // We've logged the session status, now reset.
                _secondsSpentInCurrentSession = 0;
                _numInterruptionsInCurrentSession = 0;
            }
        }
    }
}

+ (void)setSourceApplication:(NSString *)sourceApplication openURL:(NSURL *)url
{
    [self setSourceApplication:sourceApplication
                 isFromAppLink:[YUNInternalUtility dictionaryFromURL:url][@"al_applink_data"] != nil];
}

+ (void)setSourceApplication:(NSString *)sourceApplication isFromAppLink:(BOOL)isFromAppLink
{
    g_isOpenedFromAppLink = isFromAppLink;
    g_sourceApplication = sourceApplication;
}

+ (NSString *)getSourceApplication
{
    NSString *openType = @"Unclassified";
    if (g_isOpenedFromAppLink) {
        openType = @"AppLink";
    }
    return (g_sourceApplication ? [NSString stringWithFormat:@"%@(%@)", openType, g_sourceApplication] : openType);
}

+ (void)resetSourceApplication
{
    g_sourceApplication = nil;
    g_isOpenedFromAppLink = NO;
}

+ (void)registerAutoResetSourceApplication
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetSourceApplication)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

@end
