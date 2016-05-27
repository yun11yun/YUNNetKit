//
//  YUNAppEventsStateManager.m
//  YUNNetKit
//
//  Created by Orange on 5/27/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAppEventsStateManager.h"

#import "YUNAppEventsState.h"
#import "YUNAppEventsUtility.h"
#import "YUNLogger.h"
#import "YUNSettings.h"

// A quick optimization to allow returning empty array if we know there are no persisted events.
static BOOL g_canSkipDiskCheck = NO;

@implementation YUNAppEventsStateManager

+ (void)clearPersistedAppEventsStates
{
    [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                           logEntry:@"YUNAppEvents Persist: Clearing"];
    [[NSFileManager defaultManager] removeItemAtPath:[[self class] filePath]
                                               error:NULL];
    g_canSkipDiskCheck = YES;
}

+ (void)persistAppEventsData:(YUNAppEventsState *)appEventsState
{
    [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                       formatString:@"YUNAppEvents Persist: Writing %lu events", (unsigned long)appEventsState.events.count];
    
    if (!appEventsState.events.count) {
        return;
    }
    NSMutableArray *existingEvents = [NSMutableArray arrayWithArray:[[self class] retrievePersistedAppEventsStates]];
    [existingEvents addObject:appEventsState];
    
    [NSKeyedArchiver archiveRootObject:existingEvents toFile:[[self class] filePath]];
    g_canSkipDiskCheck = NO;
}

+ (NSArray *)retrievePersistedAppEventsStates
{
    NSMutableArray *eventsStates = [NSMutableArray array];
    if (!g_canSkipDiskCheck) {
        [eventsStates addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] filePath]]];
        
        [YUNLogger singleShotLogEntry:YUNLoggingBehaviorAppEvents
                           formatString:@"FBSDKAppEvents Persist: Read %lu event states. First state has %lu events",
         (unsigned long)eventsStates.count,
         (unsigned long)(eventsStates.count > 0 ? ((YUNAppEventsState *)eventsStates[0]).events.count : 0)];
        [[self class] clearPersistedAppEventsStates];
    }
    return eventsStates;
}

#pragma mark - Private Helpers

+ (NSString *)filePath
{
    return [YUNAppEventsUtility persistenceFilePath:@"com-facebook-sdk-AppEventsPersistedEvents.json"];
}

@end
