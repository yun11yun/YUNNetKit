//
//  YUNCrypto.m
//  YUNNetKit
//
//  Created by Orange on 5/31/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNCrypto.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "YUNBase64.h"
#import "YUNDynamicFrameworkLoader.h"

static const uint8_t kYUN_CRYPTO_CURRENT_VERSION = 1;
static const uint8_t kYUN_CRYPTO_CURRENT_MASTER_KEY_LENGTH = 16;

static inline void YUNCryptoWriteIntBigEndian(uint8_t *buffer, uint32_t value)
{
    buffer[3] = (uint8_t)(value & 0xff);
    buffer[2] = (uint8_t)((value >> 8) & 0xff);
    buffer[1] = (uint8_t)((value >> 16) & 0xff);
    buffer[0] = (uint8_t)((value >> 24) & 0xff);
}

static inline void YUNCryptoBlankData(NSData *data)
{
    if (!data) {
        return;
    }
    bzero((void *) [data bytes], [data length]);
}

// Note: the following simple derivation function is NOT suitable for passwords or weak keys
static inline NSData *YUNCryptoMakeSubKey(uint8_t *key, size_t len, uint32_t idx)
{
    if (!key || len < 10) {
        return nil;
    }
    
    size_t macBufferLength = 4;
    uint8_t macBuffer[4];
    YUNCryptoWriteIntBigEndian(macBuffer, idx);
    
    uint8_t *result = malloc(CC_SHA256_DIGEST_LENGTH);
    if (!result) {
        return nil;
    }
    
    CCHmac(kCCHmacAlgSHA256, key, len, macBuffer, macBufferLength, result);
    
    return [NSData dataWithBytesNoCopy:result length:CC_SHA256_DIGEST_LENGTH];
}

@implementation YUNCrypto
{
    NSData *_encryptionKeyData;
    NSData *_macKeyData;
}

#pragma mark - Class Methods

+ (NSString *)makeMasterKey
{
    NSData *masterKeyData = [YUNCrypto randomBytes:kYUN_CRYPTO_CURRENT_MASTER_KEY_LENGTH + 1];
    
    // force the first byte to be the crypto version
    uint8_t *first = (uint8_t *) [masterKeyData bytes];
    *first = kYUN_CRYPTO_CURRENT_VERSION;
    
    NSString *masterKey = [YUNBase64 encodeData:masterKeyData];
    YUNCryptoBlankData(masterKeyData);
    return masterKey;
}

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

+ (NSString *)randomString:(NSUInteger)numOfBytes
{
    NSData *randomStringData = [YUNCrypto randomBytes:numOfBytes];
    NSString *randomString = [YUNBase64 encodeData:randomStringData];
    YUNCryptoBlankData(randomStringData);
    return randomString;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithMasterKey:(NSString *)masterKey
{
    if ((self = [super init])) {
        NSData *masterKeyData = [YUNBase64 decodeAsData:masterKey];
        NSUInteger len = [masterKeyData length];
        uint8_t *first = (uint8_t *) [masterKeyData bytes];
        
        if (len == 0 || first == nil || *first != kYUN_CRYPTO_CURRENT_VERSION) {
            // only one version supported at the moment
            return nil;
        }
        
        _encryptionKeyData = YUNCryptoMakeSubKey(first+1, len-1, 1);
        _macKeyData = YUNCryptoMakeSubKey(first+1, len-1, 2);
        YUNCryptoBlankData(masterKeyData);
        return self;
    } else {
        return nil;
    }
}

- (instancetype)initWithEncryptionKey:(NSString *)encryptionKey macKey:(NSString *)macKey
{
    if ((self = [super init])) {
        _macKeyData = [YUNBase64 decodeAsData:macKey];
        _encryptionKeyData = [YUNBase64 decodeAsData:encryptionKey];
    }
    return self;
}

- (void)dealloc
{
    YUNCryptoBlankData(_encryptionKeyData);
    YUNCryptoBlankData(_macKeyData);
}

#pragma mark - Public Methods

/**
 * return base64_encode([VERSION 1 byte] + [MAC 32 bytes] + [IV 16 bytes] + [AES256(Padded Data, multiples of 16)]
 */
- (NSString *)encrypt:(NSData *)plainText additionalDataToSign:(NSData *)additionalDataToSign
{
    NSAssert(plainText.length <= INT_MAX, @"");
    int plainTextLength = (int)plainText.length;
    
    uint8_t numPaddingBytes = kCCBlockSizeAES128 - (plainText.length % kCCBlockSizeAES128); // Pad 1 .. 16 bytes
    int cipherDataLength = plainTextLength + numPaddingBytes;
    size_t bufferSize = 1 + CC_SHA256_DIGEST_LENGTH + kCCBlockSizeAES128 + cipherDataLength;
    int offsetMAC = 1;
    int offsetIV = offsetMAC + CC_SHA256_DIGEST_LENGTH;
    int offsetCipherData = offsetIV + kCCBlockSizeAES128;
    
    uint8_t *buffer = calloc(bufferSize, sizeof(uint8_t));
    buffer[0] = kYUN_CRYPTO_CURRENT_VERSION; // First byte is the version number
    NSData *IV = [[self class] randomBytes:kCCBlockSizeAES128];
    memcpy(buffer + offsetIV, IV.bytes, IV.length);
    
    memcpy(buffer + offsetCipherData, plainText.bytes, plainTextLength); // Copy input in
    yundfl_SecRandomCopyBytes([YUNDynamicFrameworkLoader loadkSecRandomDefault],
                                numPaddingBytes,
                                buffer + offsetCipherData + plainTextLength); // Random pad
    buffer[offsetCipherData + cipherDataLength - 1] = numPaddingBytes; // Record the number of padded bytes at the end
    
    size_t numOutputBytes = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, 0,
                                          _encryptionKeyData.bytes, kCCKeySizeAES256,
                                          IV.bytes,
                                          buffer + offsetCipherData, cipherDataLength,
                                          buffer + offsetCipherData, cipherDataLength,
                                          &numOutputBytes);
    
    NSData *mac = [self _macForIV:IV
                       cipherData:[NSData dataWithBytesNoCopy:buffer + offsetCipherData length:cipherDataLength freeWhenDone:NO]
             additionalDataToSign:additionalDataToSign];
    memcpy(buffer + offsetMAC, mac.bytes, CC_SHA256_DIGEST_LENGTH);
    
    if (cryptStatus == kCCSuccess) {
        return [YUNBase64 encodeData:[NSData dataWithBytesNoCopy:buffer length:bufferSize]];
    }
    free(buffer);
    return nil;
}

- (NSData *)decrypt:(NSString *)base64EncodedCipherText additionalSignedData:(NSData *)additionalSignedData
{
    NSData *cipherText = [YUNBase64 decodeAsData:base64EncodedCipherText];
    NSAssert(cipherText.length <= INT_MAX, @"");
    int cipherTextLength = (int)cipherText.length;
    
    if (!cipherText || cipherTextLength < 1 + CC_SHA256_DIGEST_LENGTH + kCCBlockSizeAES128) {
        return nil;
    }
    int cipherDataLength = cipherTextLength  - (1 + CC_SHA256_DIGEST_LENGTH + kCCBlockSizeAES128);
    if (cipherDataLength % kCCBlockSizeAES128 != 0) {
        return nil;
    }
    uint8_t *buffer = (uint8_t *)cipherText.bytes;
    
    int offsetMAC = 1;
    int offsetIV = offsetMAC + CC_SHA256_DIGEST_LENGTH;
    int offsetCipherData = offsetIV + kCCBlockSizeAES128;
    
    if (buffer[0] != kYUN_CRYPTO_CURRENT_VERSION) {
        return nil; // Version does not match
    }
    
    NSData *IV = [NSData dataWithBytesNoCopy:buffer + offsetIV length:kCCBlockSizeAES128 freeWhenDone:NO];
    NSData *cipherData = [NSData dataWithBytesNoCopy:buffer + offsetCipherData length:cipherDataLength freeWhenDone:NO];
    NSData *mac = [self _macForIV:IV cipherData:cipherData additionalDataToSign:additionalSignedData];
    NSData *macFromStream = [NSData dataWithBytesNoCopy:buffer + offsetMAC length:CC_SHA256_DIGEST_LENGTH freeWhenDone:NO];
    if (![mac isEqualToData:macFromStream]) {
        return nil; // MAC does not match
    }
    
    
    uint8_t *outputBuffer = malloc(cipherDataLength);
    size_t numOutputBytes = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, 0,
                                          _encryptionKeyData.bytes, kCCKeySizeAES256,
                                          IV.bytes,
                                          buffer + offsetCipherData, cipherDataLength,
                                          outputBuffer, cipherDataLength,
                                          &numOutputBytes);
    if (cryptStatus == kCCSuccess) {
        int numPaddingBytes = outputBuffer[cipherDataLength - 1];
        if (!(numPaddingBytes >= 1 && numPaddingBytes <= kCCBlockSizeAES128)) {
            numPaddingBytes = 0;
        }
        return [NSData dataWithBytesNoCopy:outputBuffer length:cipherDataLength - numPaddingBytes];
    }
    free(outputBuffer);
    return nil;
}

#pragma mark - Helper Methods

/**
 *
 * [IV 16 bytes] . [length of ciphertext 4 bytes] . [ciphertext] . [length of additionalDataToSign, 4 bytes] . [additionalDataToSign])
 * length is written in big-endian
 */
- (NSData *)_macForIV:(NSData *)IV cipherData:(NSData *)cipherData additionalDataToSign:(NSData *)additionalDataToSign
{
    NSAssert(cipherData.length <= INT_MAX, @"");
    int cipherDataLength = (int)cipherData.length;
    
    NSAssert(additionalDataToSign.length <= INT_MAX, @"");
    int additionalDataToSignLength = (int)additionalDataToSign.length;
    
    size_t macBufferLength = kCCBlockSizeAES128 + 4 + cipherData.length + 4 + additionalDataToSign.length;
    uint8_t *macBuffer = malloc(macBufferLength);
    int offsetIV = 0;
    int offsetCipherTextLength = offsetIV + kCCBlockSizeAES128;
    int offsetCipherText = offsetCipherTextLength + 4;
    
    int offsetAdditionalDataLength = offsetCipherText + cipherDataLength;
    int offsetAdditionalData = offsetAdditionalDataLength + 4;
    
    // [IV 16 bytes]
    memcpy(macBuffer + offsetIV, IV.bytes, kCCBlockSizeAES128);
    // [length of ciphertext 4 bytes]
    YUNCryptoWriteIntBigEndian(macBuffer + offsetCipherTextLength, cipherDataLength);
    // [ciphertext]
    memcpy(macBuffer + offsetCipherText, cipherData.bytes, cipherDataLength);
    // [length of additionalDataToSign, 4 bytes]
    YUNCryptoWriteIntBigEndian(macBuffer + offsetAdditionalDataLength, additionalDataToSignLength);
    memcpy(macBuffer + offsetAdditionalData, additionalDataToSign.bytes, additionalDataToSignLength);
    
    uint8_t *result = malloc(CC_SHA256_DIGEST_LENGTH);
    
    CCHmac(kCCHmacAlgSHA256, _macKeyData.bytes, _macKeyData.length, macBuffer, macBufferLength, result);
    free(macBuffer);
    
    return [NSData dataWithBytesNoCopy:result length:CC_SHA256_DIGEST_LENGTH];
}

@end
