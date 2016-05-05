//
//  YUNRequestBody.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@class YUNRequestDataAttachment;
@class YUNLogger;

@interface YUNRequestBody : NSObject

@property (nonatomic, retain, readonly) NSData *data;

- (void)appendWithKey:(NSString *)key
            fromValue:(NSString *)value
               logger:(YUNLogger *)logger;

- (void)appendWithKey:(NSString *)key
           imageValue:(UIImage *)image
               logger:(YUNLogger *)logger;

- (void)appendWithKey:(NSString *)key
            dataValue:(NSData *)data
               logger:(YUNLogger *)logger;

- (void)appendWithKey:(NSString *)key
  dataAttachmentValue:(YUNRequestDataAttachment *)dataAttachment
               logger:(YUNLogger *)logger;

+ (NSString *)mimeContentType;


@end
