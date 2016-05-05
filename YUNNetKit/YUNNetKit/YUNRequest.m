//
//  YUNRequest.m
//  YUNNetKit
//
//  Created by bit_tea on 16/5/3.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNRequest+Internal.h"

#import <UIKit/UIKit.h>

#import "YUNAccessToken.h"
#import "YUNRequestConnection.h"
#import "YUNRequestDataAttachment.h"
#import "YUNInternalUtility.h"
#import "YUNLogger.h"
#import "YUNSettings+Internal.h"

// constants
static NSString *const kGetHTTPMethod = @"GET";

@interface YUNRequest ()

@property (nonatomic, assign) YUNRequestFlags flags;

@end

@implementation YUNRequest

- (instancetype)init NS_UNAVAILABLE
{
    assert(0);
}

- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
{
    return [self initWithPath:path
                   parameters:parameters
                        flags:YUNRequestFlagNone];
}

- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                  HTTPMethod:(NSString *)HTTPMethod
{
    return [self initWithPath:path
                   parameters:parameters
                  tokenString:[YUNAccessToken currentAccessToken].tokenString
                   HTTPMethod:HTTPMethod];
}

- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                 tokenString:(NSString *)tokenString
                  HTTPMethod:(NSString *)HTTPMethod
                       flags:(YUNRequestFlags)flags{
    if ((self = [self initWithPath:path
                        parameters:parameters
                       tokenString:tokenString
                        HTTPMethod:HTTPMethod])) {
        self.flags |= flags;
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path
                  parameters:(NSDictionary *)parameters
                 tokenString:(NSString *)tokenString
                  HTTPMethod:(NSString *)HTTPMethod {
    if ((self = [super init])) {
        _tokenString = [tokenString copy];
        _path = [path copy];
        _HTTPMethod = HTTPMethod ? [HTTPMethod copy] : kGetHTTPMethod;
        _parameters = [[NSMutableDictionary alloc] initWithDictionary:parameters];
        if ([YUNSettings isGraphErrorRecoveryDisabled]) {
            _flags = YUNRequestFlagDisableErrorRecovery;
        }
    }
    return self;
}

- (BOOL)isGraphErrorRecoveryDisabled
{
    return (self.flags & YUNRequestFlagDisableErrorRecovery);
}

- (void)setGraphErrorRecoveryDisabled:(BOOL)disable
{
    if (disable) {
        self.flags |= YUNRequestFlagDisableErrorRecovery;
    } else {
        self.flags &= ~YUNRequestFlagDisableErrorRecovery;
    }
}

- (BOOL)hasAttachments
{
    __block BOOL hasAttachments = NO;
    [self.parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([YUNRequest isAttachment:obj]) {
            hasAttachments = YES;
            *stop = YES;
        }
    }];
    return hasAttachments;
}

+ (BOOL)isAttachment:(id)item
{
    return ([item isKindOfClass:[UIImage class]] ||
            [item isKindOfClass:[NSData class]] ||
            [item isKindOfClass:[YUNRequestDataAttachment class]]);
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params {
    return [self serializeURL:baseUrl
                       params:params
                   httpMethod:kGetHTTPMethod];
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params
                httpMethod:(NSString *)httpMethod {
    params = [self preprocessParams:params];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSURL *parsedURL = [NSURL URLWithString:[baseUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
#pragma clang pop
    NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
    NSString *query = nil;
    
    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

+ (NSDictionary *)preprocessParams:(NSDictionary *)params
{
    NSString *debugValue = [YUNSettings graphAPIDebugParamValue];
    if (debugValue) {
        NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
        [mutableParams setObject:debugValue forKey:@"debug"];
        return mutableParams;
    }
    
    return params;
}

@end
