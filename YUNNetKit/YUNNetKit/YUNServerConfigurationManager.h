//
//  YUNServerConfigurationManager.h
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNServerConfiguration.h"

typedef void(^YUNServerConfigurationManagerLoadBlock)(YUNServerConfiguration *serverConfiguration, NSError *error);

@interface YUNServerConfigurationManager : NSObject

/**
 *  @abstract Returns the locally cached configuration.
 *  @discussion The result will be valid for the appID from YUNSettings, but may be expired. A network request will be initiated to update the configuration if a valid and unexpired configuration is not available.
 */
+ (YUNServerConfiguration *)cachedServerConfiguration;

/**
 *  @abstract Executes the completionBlock with a valid and current configuration when it is available
 *
 *  @discussion This method will use a cached configuration if it is valid and not expired.
 */
+ (void)loadServerConfigurationWithCompletionBlock:(YUNServerConfigurationManagerLoadBlock)completionBlock;

@end
