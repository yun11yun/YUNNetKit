//
//  YUNAccessTokenCaching.h
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YUNAccessToken;

@protocol YUNAccessTokenCaching <NSObject>

- (YUNAccessToken *)fetchAccessToken;

- (void)cacheAccessToken;

- (void)clearCache;

@end
