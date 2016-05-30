//
//  YUNUtility.m
//  YUNNetKit
//
//  Created by Orange on 5/5/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNUtility.h"

#import "YUNInternalUtility.h"
#import "YUNMacros.h"

@implementation YUNUtility

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSArray *parts = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *part in parts) {
        if ([part length] == 0) {
            continue;
        }
        
        NSRange index = [part rangeOfString:@"="];
        NSString *key;
        NSString *value;
        
        if (index.location == NSNotFound) {
            key = part;
            value = @"";
        } else {
            key = [part substringToIndex:index.location];
            value = [part substringFromIndex:index.location + index.length];
        }
        
        key = [self URLDecode:key];
        value = [self URLDecode:value];
        if (key && value) {
            result[key] = value;
        }
    }
    return result;
}

+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionry error:(NSError *__autoreleasing *)errorRef
{
    return [YUNInternalUtility queryStringWithDictionary:dictionry error:errorRef invalidObjectHandler:NULL];
}

+ (NSString *)URLDecode:(NSString *)value
{
    value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    return value;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (NSString *)URLEncode:(NSString *)value
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)value,
                                                                                 NULL, // characters to leave unescaped
                                                                                 CFSTR(":!*();@/&?+$,='"),
                                                                                 kCFStringEncodingUTF8);
}
#pragma clang diagnostic pop

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

@end
