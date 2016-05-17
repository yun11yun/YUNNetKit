//
//  YUNErrorRecoveryAttempter.m
//  YUNNetKit
//
//  Created by Orange on 5/17/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNErrorRecoveryAttempter.h"

#import "_YUNTemporaryErrorRecoveryAttempter.h"
#import "YUNErrorRecoveryConfiguration.h"

@implementation YUNErrorRecoveryAttempter

+ (instancetype)recoveryAttempterFromConfiguration:(YUNErrorRecoveryConfiguration *)configuration
{
    if (configuration.errorCategory == YUNRequestErrorCategoryTransient) {
        return [[_YUNTemporaryErrorRecoveryAttempter alloc] init];
    } else if (configuration.errorCategory == YUNRequestErrorCategoryOther) {
        return nil;
    }
    if ([configuration.recoveryActionName isEqualToString:@"login"]) {
        Class loginRecoveryAttmpterClass = NSClassFromString(@"_YUNLoginRecoveryAttempter");
        if (loginRecoveryAttmpterClass) {
            return [[loginRecoveryAttmpterClass alloc] init];
        }
    }
    return nil;
}

- (void)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo
{
    // should be implemeted by subclass.
}
@end

@implementation YUNErrorRecoveryAttempter(Protected)

- (void)completeRecovery:(BOOL)didRecover delegate:(id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(void *)contextInfo
{
    void (*callback)(id, SEL, BOOL, void *) = (void *)[delegate methodForSelector:didRecoverSelector];
    (*callback)(delegate, didRecoverSelector, didRecover, contextInfo);
}

@end