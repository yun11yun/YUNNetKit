//
//  YUNErrorRecoveryConfiguration.h
//  YUNNetKit
//
//  Created by Orange on 5/5/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNContants.h"

@interface YUNErrorRecoveryConfiguration : NSObject<NSCopying, NSSecureCoding>

@property (nonatomic, readonly) NSString *localizedRecoveryDescription;
@property (nonatomic, readonly) NSArray *localizedRecoveryOptionDescriptions;
@property (nonatomic, readonly) YUNRequestErrorCategory errorCategory;
@property (nonatomic, readonly) NSString *recoveryActionName;

- (instancetype)initWithRecoveryDescription:(NSString *)description
                         optionDescriptions:(NSArray *)optionDescriptions
                                   category:(YUNRequestErrorCategory)category
                         recoveryActionName:(NSString *)recoveryActionName
NS_DESIGNATED_INITIALIZER;

@end
