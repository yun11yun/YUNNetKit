//
//  YUNRequestDataAttachment.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNRequestDataAttachment.h"

#import "YUNMacros.h"

@implementation YUNRequestDataAttachment

- (instancetype)initWithData:(NSData *)data
                    filename:(NSString *)filename
                 contentType:(NSString *)contentType
{
    if (self = [super init]) {
        _data = data;
        _filename = [filename copy];
        _contentType = [contentType copy];
    }
    return self;
}

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithData:filename:contentType:);
    return [self initWithData:nil filename:nil contentType:nil];
}

@end
