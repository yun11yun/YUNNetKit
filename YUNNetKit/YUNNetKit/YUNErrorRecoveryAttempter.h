//
//  YUNErrorRecoveryAttempter.h
//  YUNNetKit
//
//  Created by Orange on 5/17/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNContants.h"

@class YUNErrorRecoveryConfiguration;

@interface YUNErrorRecoveryAttempter : NSObject<YUNErrorRecoveryAttempting>

// can return nil if configuration is not supported.
+ (instancetype)recoveryAttempterFromConfiguration:(YUNErrorRecoveryConfiguration *)configuration;

@end

@interface YUNErrorRecoveryAttempter (Protected)

- (void)completeRecovery:(BOOL)didRecover delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo;

@end