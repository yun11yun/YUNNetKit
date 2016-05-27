//
//  YUNAppEventsState.m
//  YUNNetKit
//
//  Created by Orange on 5/27/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNAppEventsState.h"

#import "YUNInternalUtility.h"
#import "YUNMacros.h"

#define YUN_APPEVENTSTATE_ISIMPLICIT_KEY @"isImplicit"

#define YUN_APPEVENTSSTATE_MAX_EVENTS 1000

#define YUN_APPEVENTSSTATE_APPID_KEY @"appID"
#define YUN_APPEVENTSSTATE_EVENTS_KEY @"events"
#define YUN_APPEVENTSSTATE_NUMSKIPPED_KEY @"numSkipped"
#define YUN_APPEVENTSSTATE_TOKENSTRING_KEY @"tokenString"

@implementation YUNAppEventsState
{
    NSMutableArray *_mutableEvnets;
}

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithToken:appID:);
    return [self initWithToken:nil appID:nil];
}

- (instancetype)initWithToken:(NSString *)tokenString appID:(NSString *)appID
{
    if ((self = [super init])) {
        _tokenString = [tokenString copy];
        _appID = [appID copy];
        _mutableEvnets = [NSMutableArray array];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    YUNAppEventsState *copy = [[YUNAppEventsState allocWithZone:zone] initWithToken:_tokenString appID:_appID];
    if (copy) {
        [copy->_mutableEvnets addObjectsFromArray:_mutableEvnets];
        copy->_numSkipped = _numSkipped;
    }
    return copy;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSString *appID = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_APPEVENTSSTATE_APPID_KEY];
    NSString *tokenString = [decoder decodeObjectOfClass:[NSString class] forKey:YUN_APPEVENTSSTATE_TOKENSTRING_KEY];
    NSArray *events = [decoder decodeObjectOfClass:[NSArray class] forKey:YUN_APPEVENTSSTATE_EVENTS_KEY];
    NSUInteger numSkipped = [[decoder decodeObjectOfClass:[NSNumber class] forKey:YUN_APPEVENTSSTATE_NUMSKIPPED_KEY] unsignedIntegerValue];
    
    if ((self = [self initWithToken:tokenString appID:appID])) {
        _mutableEvnets = [NSMutableArray arrayWithArray:events];
        _numSkipped = numSkipped;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_appID forKey:YUN_APPEVENTSSTATE_APPID_KEY];
    [encoder encodeObject:_tokenString forKey:YUN_APPEVENTSSTATE_TOKENSTRING_KEY];
    [encoder encodeObject:@(_numSkipped) forKey:YUN_APPEVENTSSTATE_NUMSKIPPED_KEY];
    [encoder encodeObject:_mutableEvnets forKey:YUN_APPEVENTSSTATE_EVENTS_KEY];
}

#pragma mark - Implementation

- (NSArray *)events
{
    return [_mutableEvnets copy];
}

- (void)addEventsFromAppEventState:(YUNAppEventsState *)appEventsState
{
    NSArray *toAdd = appEventsState->_mutableEvnets;
    NSInteger excess  = _mutableEvnets.count + toAdd.count - YUN_APPEVENTSSTATE_MAX_EVENTS;
    if (excess > 0) {
        NSInteger range = YUN_APPEVENTSSTATE_MAX_EVENTS - _mutableEvnets.count;
        toAdd = [toAdd subarrayWithRange:NSMakeRange(0, range)];
        _numSkipped += excess;
    }
    
    [_mutableEvnets addObjectsFromArray:toAdd];
}

- (void)addEvent:(NSDictionary *)eventDictionary
      isImplicit:(BOOL)isImplicit {
    if (_mutableEvnets.count >= YUN_APPEVENTSSTATE_MAX_EVENTS) {
        _numSkipped++;
    } else {
        [_mutableEvnets addObject:@{
                                    @"event" : eventDictionary,
                                    YUN_APPEVENTSTATE_ISIMPLICIT_KEY : @(isImplicit)
                                    }];
    }
}

- (BOOL)areAllEventsImplicit
{
    for (NSDictionary *event in _mutableEvnets) {
        if (![[event valueForKey:YUN_APPEVENTSTATE_ISIMPLICIT_KEY] boolValue]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isCompatibleWithAppEvnetsState:(YUNAppEventsState *)appEventsState
{
    return ([self isCompatibleWithTokenString:appEventsState.tokenString appID:appEventsState.appID]);
}

- (BOOL)isCompatibleWithTokenString:(NSString *)tokenString appID:(NSString *)appID
{
    // token strings can be nil (e.g., no user token) but appIDs should not.
    BOOL tokenCompatible = ([self.tokenString isEqualToString:tokenString] ||
                            (self.tokenString == nil && tokenString == nil));
    return (tokenCompatible && [self.appID isEqualToString:appID]);
}

- (NSString *)JSONStringForEvents:(BOOL)includeImplicitEvents
{
    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:_mutableEvnets.count];
    for (NSDictionary *eventAndImplicitFlag in _mutableEvnets) {
        if (!includeImplicitEvents && [eventAndImplicitFlag[YUN_APPEVENTSTATE_ISIMPLICIT_KEY] boolValue]) {
            continue;
        }
        [events addObject:eventAndImplicitFlag[@"event"]];
    }
    
    return [YUNInternalUtility JSONStringForObject:events error:NULL invalidObjectHandler:NULL];
}

@end
