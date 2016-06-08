//
//  YUNTypeUtilityTest.m
//  YUNNetKit
//
//  Created by Orange on 5/31/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "YUNTypeUtility.h"

@interface YUNTypeUtilityTest : XCTestCase

@end

@implementation YUNTypeUtilityTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test
{
    NSObject *object = [NSObject new];
    BOOL yes = [YUNTypeUtility boolValue:object];
    XCTAssert(yes == YES);
    
    NSString *numerString = @"26f";
    NSInteger number = [YUNTypeUtility integerValue:numerString];
    XCTAssert(number == 26);
}

@end
