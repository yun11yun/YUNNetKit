//
//  YUNRequestBody.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNRequestBody.h"

#import "YUNRequestDataAttachment.h"
#import "YUNLogger.h"
#import "YUNSettings.h"

#define kStringBoundary @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f"
#define kNewline @"\r\n"

@implementation YUNRequestBody
{
    NSMutableData *_data;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

+ (NSString *)mimeContentType
{
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
}

- (void)appendUTF8:(NSString *)utf8
{
    if (![_data length]) {
        NSString *headerUTF8 = [NSString stringWithFormat:@"--%@%@", kStringBoundary, kNewline];
        NSData *headerData = [headerUTF8 dataUsingEncoding:NSUTF8StringEncoding];
        [_data appendData:headerData];
    }
    NSData *data = [utf8 dataUsingEncoding:NSUTF8StringEncoding];
    [_data appendData:data];
}

- (void)appendWithKey:(NSString *)key
            fromValue:(NSString *)value
               logger:(YUNLogger *)logger
{
    [self _appendWithKey:key filename:nil contentType:nil contentBlock:^{
        [self appendUTF8:value];
    }];
    [logger appendFormat:@"\n    %@:\t%@", key, (NSString *)value];
}

- (void)appendWithKey:(NSString *)key
           imageValue:(UIImage *)image
               logger:(YUNLogger *)logger
{
    NSData *data = UIImageJPEGRepresentation(image, [YUNSettings JPEGCompressionQuality]);
    [self _appendWithKey:key filename:key contentType:@"image/jpeg" contentBlock:^{
        [_data appendData:data];
    }];
    [logger appendFormat:@"\n    %@:\t<Image - %lu kB>", key, (unsigned long)([data length] / 1024)];
}

- (void)appendWithKey:(NSString *)key
            dataValue:(NSData *)data
               logger:(YUNLogger *)logger
{
    [self _appendWithKey:key filename:key contentType:@"content/unknown" contentBlock:^{
        [_data appendData:data];
    }];
    [logger appendFormat:@"\n    %@:\t<Data - %lu kB>", key, (unsigned long)([data length] / 1024)];
}

- (void)appendWithKey:(NSString *)key
  dataAttachmentValue:(YUNRequestDataAttachment *)dataAttachment
               logger:(YUNLogger *)logger
{
    NSString *filename = dataAttachment.filename ?: key;
    NSString *contentType = dataAttachment.contentType ?: @"content/unknown";
    NSData *data = dataAttachment.data;
    [self _appendWithKey:key filename:filename contentType:contentType contentBlock:^{
        [_data appendData:data];
    }];
    [logger appendFormat:@"\n    %@:\t<Data - %lu kB>", key, (unsigned long)([data length] / 1024)];
}

- (NSData *)data
{
    return [_data copy];
}

- (void)_appendWithKey:(NSString *)key
              filename:(NSString *)filename
           contentType:(NSString *)contentType
          contentBlock:(void(^)(void))contentBlock
{
    NSMutableArray *disposition = [[NSMutableArray alloc] init];
    [disposition addObject:@"Content-Disposition: form-data"];
    if (key) {
        [disposition addObject:[[NSString alloc] initWithFormat:@"name=\"%@\"", key]];
    }
    if (filename) {
        [disposition addObject:[[NSString alloc] initWithFormat:@"filename=\"%@\"", filename]];
    }
    [self appendUTF8:[[NSString alloc] initWithFormat:@"%@%@", [disposition componentsJoinedByString:@"; "], kNewline]];
    if (contentType) {
        [self appendUTF8:[[NSString alloc] initWithFormat:@"Content-Type: %@%@", contentType, kNewline]];
    }
    [self appendUTF8:kNewline];
    if (contentBlock != NULL) {
        contentBlock();
    }
    [self appendUTF8:[[NSString alloc] initWithFormat:@"%@--%@%@", kNewline, kStringBoundary, kNewline]];
}

@end
