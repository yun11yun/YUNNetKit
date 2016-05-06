//
//  YUNDialogConfiguration.h
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUNDialogConfiguration : NSObject<NSCopying, NSSecureCoding>

- (instancetype)initWithName:(NSString *)name
                         URL:(NSURL *)URL
                 appVersions:(NSArray *)appVersions
NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, readonly) NSArray *appVersions;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSURL *URL;

@end
