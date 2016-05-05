//
//  YUNRequest+Internal.h
//  YUNNetKit
//
//  Created by bit_tea on 16/5/4.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUNRequest.h"

typedef NS_OPTIONS(NSUInteger, YUNRequestFlags)
{
    YUNRequestFlagNone = 0,
    
    // indicates this request should not use a client token as its token parameter
    YUNRequestFlagSkipClientToken = 1 << 1,
    
    // indicates this request should not close the session if its response is an oauth error
    YUNRequestFlagDoNotInvalidateTokenOnError = 1 << 2,
    
    // indicates this request should not perform error recovery
    YUNRequestFlagDisableErrorRecovery = 1 << 3,
};

@interface YUNRequest (Internal)

- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                       flags:(YUNRequestFlags)flags;
- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                 tokenString:(NSString *)tokenString
                  HTTPMethod:(NSString *)HTTPMethod
                       flags:(YUNRequestFlags)flags;

// Generally, requests automatically issued by the SDK
// should not invalidate the token and should disableErrorRecovery
// so that we don't cause a sudden change in token state or trigger recovery
// out of context of any user action.
@property (nonatomic, assign) YUNRequestFlags flags;

- (BOOL)isGraphErrorRecoveryDisabled;
- (BOOL)hasAttachments;
+ (BOOL)isAttachment:(id)item;
+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params
                httpMethod:(NSString *)httpMethod;

@end
