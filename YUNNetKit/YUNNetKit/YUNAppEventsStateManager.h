//
//  YUNAppEventsStateManager.h
//  YUNNetKit
//
//  Created by Orange on 5/27/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YUNAppEventsState;

@interface YUNAppEventsStateManager : NSObject

+ (void)clearPersistedAppEventsStates;

// reads all saved event states, appends the param, and writes them all.
+ (void)persistAppEventsData:(YUNAppEventsState *)appEventsState;

// returns the array of saved app event states and deletes them.
+ (NSArray *)retrievePersistedAppEventsStates;

@end
