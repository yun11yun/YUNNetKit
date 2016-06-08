//
//  YUNBase64.m
//  YUNNetKit
//
//  Created by Orange on 5/31/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNBase64.h"

#import "YUNMacros.h"

@implementation YUNBase64
{
    BOOL _optionsEnabled;
}

static YUNBase64 *_decoder;
static YUNBase64 *_encoder;

#pragma mark - Class Methods

+ (void)initialize
{
    if (self == [YUNBase64 class]) {
        BOOL optionsEnabled;
        optionsEnabled = [NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)];
        _decoder = [[YUNBase64 alloc] initWithOptionsEnabled:optionsEnabled];
        optionsEnabled = [NSData instancesRespondToSelector:@selector(base64EncodedStringWithOptions:)];
        _encoder = [[YUNBase64 alloc] initWithOptionsEnabled:optionsEnabled];
    }
}

+ (NSData *)decodeAsData:(NSString *)string
{
    return [_decoder decodeAsData:string];
}

+ (NSString *)decodeAsString:(NSString *)string
{
    return [_decoder decodeAsString:string];
}

+ (NSString *)encodeData:(NSData *)data
{
    return [_encoder encodeData:data];
}

+ (NSString *)encodeString:(NSString *)string
{
    return [_encoder encodeString:string];
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithOptionsEnabled:);
    return nil;
}

- (instancetype)initWithOptionsEnabled:(BOOL)optionsEnabled
{
    if ((self = [super init])) {
        _optionsEnabled = optionsEnabled;
    }
    return self;
}

#pragma mark - Implementation Methods

- (NSData *)decodeAsData:(NSString *)string
{
    if (!string) {
        return nil;
    }
    // This padding will be appended before stripping unknown characters, so if there are unknown characters of count % 4
    // it will not be able to decode.  Since we assume valid base64 data, we will take this as is.
    int needPadding = string.length % 4;
    if (needPadding > 0) {
        needPadding = 4 - needPadding;
        string = [string stringByPaddingToLength:string.length+needPadding withString:@"=" startingAtIndex:0];
    }
    if (_optionsEnabled) {
        return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [[NSData alloc] initWithBase64Encoding:string];
#pragma clang diagnostic pop
    }
}

- (NSString *)decodeAsString:(NSString *)string
{
    NSData *data = [self decodeAsData:string];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)encodeData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    if (_optionsEnabled) {
        return [data base64EncodedStringWithOptions:0];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [data base64Encoding];
#pragma clang diagnostic pop
    }
}

- (NSString *)encodeString:(NSString *)string
{
    return [self encodeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
