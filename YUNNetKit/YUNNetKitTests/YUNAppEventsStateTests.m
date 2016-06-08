//
//  YUNAppEventsStateTests.m
//  YUNNetKit
//
//  Created by Orange on 5/31/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "YUNAppEventsState.h"

#import "YUNAppEventsDeviceInfo.h"

@interface YUNAppEventsStateTests : XCTestCase

@end

@implementation YUNAppEventsStateTests

- (void)testAppEventsStateAddSimple
{
    YUNAppEventsState *target = [[YUNAppEventsState alloc] initWithToken:@"token" appID:@"app"];
    XCTAssertEqual(0, target.events.count);
    XCTAssertEqual(0, target.numSkipped);
    XCTAssertTrue([target areAllEventsImplicit]);
    
    [target addEvent:@{ @"event1" : @1} isImplicit:YES];
    XCTAssertEqual(1, target.events.count);
    XCTAssertEqual(0, target.numSkipped);
    XCTAssertTrue([target areAllEventsImplicit]);
    
    [target addEvent:@{@"event2" : @2} isImplicit:NO];
    XCTAssertEqual(2, target.events.count);
    XCTAssertEqual(0, target.numSkipped);
    XCTAssertFalse([target areAllEventsImplicit]);
    
    NSString *expectedJSON = @"[{\"event1\":1},{\"event2\":2}]";
    XCTAssertEqualObjects(expectedJSON, [target JSONStringForEvents:YES]);
    
    YUNAppEventsState *copy = [target copy];
    [copy addEvent:@{@"copy1" : @3} isImplicit:YES];
    XCTAssertEqual(2, target.events.count);
    XCTAssertEqual(3, copy.events.count);
    
    [target addEventsFromAppEventState:copy];
    XCTAssertEqual(5, target.events.count);
    XCTAssertFalse([target areAllEventsImplicit]);
    
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [YUNAppEventsDeviceInfo extendDictionaryWithDeviceInfo:mutableDict];
    XCTAssertTrue(mutableDict != nil);
    
}

@end
