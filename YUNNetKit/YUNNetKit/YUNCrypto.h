//
//  YUNCrypto.h
//  YUNNetKit
//
//  Created by Orange on 5/31/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUNCrypto : NSObject

/*!
 @abstract Generate numOfBytes random data.
 @discussion This calls the system-provided function SecRandomCopyBytes, based on /dev/random.
 */
+ (NSData *)randomBytes:(NSUInteger)numOfBytes;

/**
 * Generate numOfBytes random data, base64-encoded.
 * This calls the system-provided function SecRandomCopyBytes, based on /dev/random.
 */
+ (NSString *)randomString:(NSUInteger)numOfBytes;

/*!
 @abstract Generate a fresh master key using SecRandomCopyBytes, the result is encoded in base64/.
 */
+ (NSString *)makeMasterKey;

/*!
 @abstract Initialize with a base64-encoded master key.
 @discussion This key and the current derivation function will be used to generate the encryption key and the mac key.
 */
- (instancetype)initWithMasterKey:(NSString *)masterKey;

/*!
 @abstract Initialize with base64-encoded encryption key and mac key.
 */
- (instancetype)initWithEncryptionKey:(NSString *)encryptionKey macKey:(NSString *)macKey;

/*!
 @abstract Encrypt plainText and return the base64 encoded result.
 @discussion MAC computation involves additionalDataToSign.
 */
- (NSString *)encrypt:(NSData *)plainText additionalDataToSign:(NSData *)additionalDataToSign;

/*!
 @abstract Decrypt base64EncodedCipherText.
 @discussion MAC computation involves additionalSignedData.
 */
- (NSData *)decrypt:(NSString *)base64EncodedCipherText additionalSignedData:(NSData *)additionalSignedData;

@end
