//
//  YUNAccessTokenCacheV3.h
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNAccessTokenCaching.h"
#import "YUNMacros.h"

extern NSString *const YUNTokenInforamtionUUIDKey;

@interface YUNAccessTokenCacheV3 : NSObject<YUNAccessTokenCaching>

+ (YUNAccessToken *)accessTokenForV3Dictionary:(NSDictionary *)dictionary;

@end
