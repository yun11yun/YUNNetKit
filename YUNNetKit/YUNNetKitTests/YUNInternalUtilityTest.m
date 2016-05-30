//
//  YUNInternalUtilityTest.m
//  YUNNetKit
//
//  Created by Orange on 5/30/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YUNInternalUtility.h"

@interface YUNInternalUtilityTest : XCTestCase

@end

@implementation YUNInternalUtilityTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAppURL
{
    NSURL *url = [YUNInternalUtility appURLWithHost:@"yun11yun.com" path:@"/user" queryParameters:@{@"id" : @"1"} error:NULL];
    NSString *urlString = [url absoluteString];
    XCTAssert([urlString isEqualToString:@"http://yun11yun.com/user?id=1"]);
    
    NSDictionary *params = [YUNInternalUtility dictionaryFromURL:url];
    XCTAssertEqualObjects(params, @{@"id" : @"1"});
}

- (void)testDictionary
{
    NSMutableDictionary *testDict = [NSMutableDictionary dictionary];
    [YUNInternalUtility dictionary:testDict setJSONStringForObject:@{@"id" : @"huang123"} forKey:@"number" error:NULL];
    XCTAssert([testDict isEqualToDictionary:@{@"number" : @"{\"id\":\"huang123\"}"}]);
}

@end
