//
//  YUNErrorConfiguration.h
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUNErrorRecoveryConfiguration.h"

@class YUNRequest;

/**
 *  maps codes and subcodes pairs to YUNErrorRecoveryConfiguration instances.
 */
@interface YUNErrorConfiguration : NSObject<NSSecureCoding, NSCopying>

// inialize from optional dictionary of existing configurations. If not supplied a fallback will be created.
- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

// parses the array (supplied from app settings endpoint)
- (void)parseArray:(NSArray *)array;

// NSString "code" instances support "*" wildcard semantics (nil is treated as "*" also)
// 'request' is optional, typically for identifying special graph request semantics (e.g., no recovery for client token)
- (YUNErrorRecoveryConfiguration *)recoveryConfigurationForCode:(NSString *)code subcode:(NSString *)subcode request:(YUNRequest *)request;

@end
