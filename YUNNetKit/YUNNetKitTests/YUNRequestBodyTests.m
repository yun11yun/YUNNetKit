//
//  YUNRequestBodyTests.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YUNRequestBody.h"
#import "YUNRequestDataAttachment.h"

@interface YUNRequestBodyTests : XCTestCase

@property (nonatomic, strong) YUNRequestBody *requestBody;

@end

@implementation YUNRequestBodyTests

- (void)setUp {
    [super setUp];
    _requestBody = [[YUNRequestBody alloc] init];
}

- (void)tearDown {
    _requestBody = nil;
    [super tearDown];
}

- (void)testFromValue
{
    [_requestBody appendWithKey:@"uid" fromValue:@"1" logger:nil];
    
    NSString *dataString = [[NSString alloc] initWithData:_requestBody.data encoding:NSUTF8StringEncoding];
    
    
    
}

@end
