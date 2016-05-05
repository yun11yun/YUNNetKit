//
//  YUNSettings+Internal.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNSettings.h"

@interface YUNSettings (Internal)

+ (NSString *)graphAPIDebugParamValue;

+ (BOOL)isGraphErrorRecoveryDisabled;

+ (NSString *)userAgentSuffix;
+ (void)setUserAgentSuffix:(NSString *)suffix;

@end
