//
//  YUNRequestDataAttachment.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * @abstract A container class for data attachments so that additional metadata can be provided about the attachment.
 */

@interface YUNRequestDataAttachment : NSObject

/*
 * @abstract Initializes the receiver with the attachment data and metadata.
 * @param data The attachment data (retained, not copied)
 * @param filename The filename for the attachment
 * @param contentType The content type for the attachment
 */
- (instancetype)initWithData:(NSData *)data
                    filename:(NSString *)filename
                 contentType:(NSString *)contentType
NS_DESIGNATED_INITIALIZER;

// @abstract The content type for the attachment
@property (nonatomic, copy, readonly) NSString *contentType;

// @abstract The attrachment data.
@property (nonatomic, strong, readonly) NSData *data;

// @abstract The file for the attrachment.
@property (nonatomic, copy, readonly) NSString *filename;

@end
