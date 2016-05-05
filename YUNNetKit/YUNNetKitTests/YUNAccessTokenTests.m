//
//  YUNAccessTokenTests.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YUNAccessToken.h"

@interface YUNAccessTokenTests : XCTestCase

@property (nonatomic, strong) YUNAccessToken *accessToken;

@end

static NSString *const kAccessTokenKey = @"access_token_key";

@implementation YUNAccessTokenTests

- (void)setUp {
    [super setUp];
    
    _accessToken = [[YUNAccessToken alloc] initWithTokenString:@"12fagwhqf"
                                                   permissions:[NSArray new]
                                           declinedPermissions:[NSArray new]
                                                         appID:@"fagtwagw"
                                                        userID:@"5895282"
                                                expirationDate:[NSDate dateWithTimeIntervalSinceNow:5000000]
                                                   refreshDate:[NSDate date]];
}

- (void)tearDown {
    _accessToken = nil;
    [super tearDown];
}

- (void)testEqualAndCoding
{
    YUNAccessToken *otherAccessToken = [[YUNAccessToken alloc] initWithTokenString:@"12fagwhqf"
                                                                       permissions:[NSArray new]
                                                               declinedPermissions:[NSArray new]
                                                                             appID:@"fagtwagw"
                                                                            userID:@"5895282"
                                                                    expirationDate:[NSDate dateWithTimeIntervalSinceNow:5000000]
                                                                       refreshDate:[NSDate date]];
    XCTAssert(![otherAccessToken isEqual:_accessToken]);
    XCTAssert(![otherAccessToken isEqualToAccessToken:_accessToken]);
    XCTAssertEqualObjects(_accessToken, otherAccessToken);
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
