//
//  YUNRequestMetadata.m
//  YUNNetKit
//
//  Created by Orange on 5/5/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNRequestMetadata.h"

#import "YUNRequest.h"
#import "YUNMacros.h"

@implementation YUNRequestMetadata

- (instancetype)initWithRequest:(YUNRequest *)request
              completionHandler:(YUNRequestHandler)handler
                batchParameters:(NSDictionary *)batchParameters
{
    if ((self = [super init])) {
        _request = request;
        _batchParameters = [batchParameters copy];
        _completionHandler = [handler copy];
    }
    return self;
}

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithRequest:completionHandler:batchParameters:);
    return [self initWithRequest:nil completionHandler:NULL batchParameters:nil];
}

- (void)invokeCompletionHnadlerConnection:(YUNRequestConnection *)connection
                              withResults:(id)results
                                    error:(NSError *)error
{
    if (self.completionHandler) {
        self.completionHandler(connection, results, error);
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, batchParameters: %@, completionHandler: %@, request: %@>",
            NSStringFromClass([self class]),
            self,
            self.batchParameters,
            self.completionHandler,
            self.request.description];
}

@end
