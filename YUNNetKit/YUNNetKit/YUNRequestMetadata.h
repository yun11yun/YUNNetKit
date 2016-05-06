//
//  YUNRequestMetadata.h
//  YUNNetKit
//
//  Created by Orange on 5/5/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNRequestConnection.h"

// Internal only class to facilitate YUNRequest processing, specifically
// associating YUNRequest and YUNRequestHandler instances and necssary
// data for retry precessing.

@interface YUNRequestMetadata : NSObject

@property (nonatomic, retain) YUNRequest *request;
@property (nonatomic, copy) YUNRequestHandler completionHandler;
@property (nonatomic, copy) NSDictionary *batchParameters;

- (instancetype)initWithRequest:(YUNRequest *)request
              completionHandler:(YUNRequestHandler)handler
                batchParameters:(NSDictionary *)batchParameters
NS_DESIGNATED_INITIALIZER;

- (void)invokeCompletionHnadlerConnection:(YUNRequestConnection *)connection
                              withResults:(id)results
                                    error:(NSError *)error;

@end
