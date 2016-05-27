//
//  YUNAppEventsState.h
//  YUNNetKit
//
//  Created by Orange on 5/27/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

// this type is not thread safe.
@interface YUNAppEventsState : NSObject<NSCopying, NSSecureCoding>

@property (readonly, copy) NSArray *events;
@property (readonly, assign) NSUInteger numSkipped;
@property (readonly, copy) NSString *tokenString;
@property (readonly, copy) NSString *appID;

- (instancetype)initWithToken:(NSString *)tokenString appID:(NSString *)appID NS_DESIGNATED_INITIALIZER;

- (void)addEvent:(NSDictionary *)eventDictionary isImplicit:(BOOL)isImplicit;
- (void)addEventsFromAppEventState:(YUNAppEventsState *)appEventsState;
- (BOOL)areAllEventsImplicit;
- (BOOL)isCompatibleWithAppEvnetsState:(YUNAppEventsState *)appEventsState;
- (BOOL)isCompatibleWithTokenString:(NSString *)tokenString appID:(NSString *)appID;
- (NSString *)JSONStringForEvents:(BOOL)includeImplicitEvents;

@end
