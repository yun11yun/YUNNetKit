//
//  YUNRequest.h
//  YUNNetKit
//
//  Created by bit_tea on 16/5/3.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNRequestConnection.h"

@class YUNAccessToken;

/* 
 @abstract Represents a request to the API.
 
 @discussion 'YUNRequest' encapsulates the components of a request (the 
 API path, the parameters, error recovery behavior) and should be used in conjunction with 'YUNRequestConnection' to issue the request.
 
 Nearly all APIs require an access token. Unless specified, the '[YUNAccessToken currentAccessToken]' is used. Therefore, most requests will require login first
 
 A '- start' method is provided for convenience for single requests.
 
 By default, YUNRequest will attempt to recover any errors returned from Facebook. You can disable this via 'disableErrorRecovery:'.
 @see YUNErrorRecoveryProcessor
 */
@interface YUNRequest : NSObject

/*
 @abstract Initializes a new instance that use '[YUNAccessToken currentAccessToken]'.
 @param path the path
 @param parameters the optional parameters dictionary.
 */
- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters;

/*!
 @abstract Initializes a new instance that use use `[YUNAccessToken currentAccessToken]`.
 @param path the path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 @param HTTPMethod the optional HTTP method. nil defaults to @"GET".
 */
- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                  HTTPMethod:(NSString *)HTTPMethod;

/*!
 @abstract Initializes a new instance.
 @param path the path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 @param tokenString the token string to use. Specifying nil will cause no token to be used.
 @param HTTPMethod the optional HTTP method (e.g., @"POST"). nil defaults to @"GET".
 */
- (instancetype)initWithPath:(NSString *)Path
                  parameters:(NSDictionary *)parameters
                 tokenString:(NSString *)tokenString
                  HTTPMethod:(NSString *)HTTPMethod
NS_DESIGNATED_INITIALIZER;

// @abstract The request parameters.
@property(nonatomic, strong, readonly) NSMutableDictionary *parameters;

// @abstract The access token string used by the request.
@property (nonatomic, copy, readonly) NSString *tokenString;

// @abstract The API endpoint to use for the request, for example "me"
@property (nonatomic, copy, readonly) NSString *path;

// @abstract The HTTPMethod to use for the request, for example "GET" or "POST".
@property (nonatomic, copy, readonly) NSString *HTTPMethod;

/*!
 @abstract If set, disables the automatic error recovery mechanism.
 @param disable whether to disable the automatic error recovery mechanism
 @discussion By default, non-batched YUNRequest instances will automatically try to recover
 from errors by constructing a `YUNErrorRecoveryProcessor` instance that
 re-issues the request on successful recoveries. The re-issued request will call the same
 handler as the receiver but may occur with a different `YUNRequestConnection` instance.
 
 This will override [FBSDKSettings setGraphErrorRecoveryDisabled:].
 */
- (void)setGraphErrorRecoveryDisabled:(BOOL)disable;

/*!
 @abstract Starts a connection to the Graph API.
 @param handler The handler block to call when the request completes.
 */
- (YUNRequestConnection *)startWithCompletionHandler:(YUNRequestHandler)handler;

@end
