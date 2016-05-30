//
//  YUNCryptoTest.m
//  YUNNetKit
//
//  Created by Orange on 5/30/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YUNCrypto.h"

@interface YUNCryptoTest : XCTestCase

@end

@implementation YUNCryptoTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test
{
    NSData *data = [YUNCrypto randomBytes:12];
    XCTAssert(data.length == 12);
}

@end
