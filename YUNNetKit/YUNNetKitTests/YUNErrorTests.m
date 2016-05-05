//
//  YUNErrorTests.m
//  YUNNetKit
//
//  Created by bit_tea on 16/5/3.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YUNError.h"
#import "YUNContants.h"

@interface YUNErrorTests : XCTestCase

@end

@implementation YUNErrorTests

- (void)testError
{
    NSError *firstError = [YUNError errorWithCode:YUNNetworkErrorCode message:@"1234"];
    XCTAssert([firstError.domain isEqualToString:YUNErrorDomain]);
    XCTAssertEqual(firstError.code, YUNNetworkErrorCode);
    XCTAssert([firstError.userInfo[YUNErrorDeveloperMessageKey] isEqualToString:@"1234"]);
}

- (void)testInvalidArgumentError
{
    NSString *message = @"name isn't number";
    NSError *argumentError = [YUNError invalidArgumentErrorWithName:@"name" value:@"12" message:@"name isn't number"];
    XCTAssertEqual(argumentError.code, YUNInvalidArgumentErrorCode);
    XCTAssertEqualObjects(argumentError.userInfo[YUNErrorArgumentNameKey], @"name");
    XCTAssertEqualObjects(argumentError.userInfo[YUNErrorArgumentValueKey], @"12");
    XCTAssertEqualObjects(argumentError.userInfo[YUNErrorDeveloperMessageKey], message);
}

@end
