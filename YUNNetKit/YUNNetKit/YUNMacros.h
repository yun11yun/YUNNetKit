//
//  YUNMacros.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/26.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#define YUN_NO_DESIGNATED_INITIALIZER() \
@throw [NSException exceptionWithName:NSInvalidArgumentException \
reason:[NSString stringWithFormat:@"unrecognized selector sent to instance %p", self] \
userInfo:nil]

#define YUN_NOT_DESIGNATED_INITIALIZER(DESIGNATED_INITIALIZER) \
@throw [NSException exceptionWithName:NSInvalidArgumentException \
reason:[NSString stringWithFormat:@"Please use the designated initializer [%p %@]", \
self, \
NSStringFromSelector(@selector(DESIGNATED_INITIALIZER))] \
userInfo:nil]
