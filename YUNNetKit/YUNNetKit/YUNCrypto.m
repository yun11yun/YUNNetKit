//
//  YUNCrypto.m
//  YUNNetKit
//
//  Created by Orange on 5/30/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNCrypto.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "YUNDynamicFrameworkLoader.h"

@implementation YUNCrypto

+ (NSData *)randomBytes:(NSUInteger)numOfBytes
{
    uint8_t *buffer = malloc(numOfBytes);
    int result = yundfl_SecRandomCopyBytes([YUNDynamicFrameworkLoader loadkSecRandomDefault], numOfBytes, buffer);
    if (result != 0) {
        free(buffer);
        return nil;
    }
    return [NSData dataWithBytesNoCopy:buffer length:numOfBytes];
}

@end
