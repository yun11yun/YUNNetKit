//
//  _YUNTemporaryErrorRecoveryAttempter.m
//  YUNNetKit
//
//  Created by Orange on 5/17/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "_YUNTemporaryErrorRecoveryAttempter.h"

@implementation _YUNTemporaryErrorRecoveryAttempter

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo
{
    [super completeRecovery:YES delegate:delegate didRecoverSelector:didRecoverSelector contextInfo:contextInfo];
}

@end
