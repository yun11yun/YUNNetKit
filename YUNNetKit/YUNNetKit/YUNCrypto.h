//
//  YUNCrypto.h
//  YUNNetKit
//
//  Created by Orange on 5/30/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUNCrypto : NSObject

/*!
 @abstract Generate numOfBytes random data.
 @discussion This calls the system-provided function SecRandomCopyBytes, based on /dev/random.
 */
+ (NSData *)randomBytes:(NSUInteger)numOfBytes;

@end
