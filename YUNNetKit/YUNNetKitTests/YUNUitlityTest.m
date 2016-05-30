//
//  YUNUitlityTest.m
//  YUNNetKit
//
//  Created by Orange on 5/30/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YUNUtility.h"

@interface YUNUitlityTest : XCTestCase

@end

@implementation YUNUitlityTest

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
    NSString *queryString = @"id=1";
    NSDictionary *params = [YUNUtility dictionaryWithQueryString:queryString];
    XCTAssert([params isEqualToDictionary:@{@"id" : @"1"}]);
    NSString *testString = [YUNUtility queryStringWithDictionary:params error:NULL];
    XCTAssert([queryString isEqualToString:testString]);
}

@end
