//
//  YUNURLConnection.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/27.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YUNURLConnection;

typedef void(^YUNURLConnectionHandler)(YUNURLConnection *connection,
                                       NSError *error,
                                       NSURLResponse *response,
                                       NSData *responseData);

@protocol YUNURLConnectionDelegate <NSObject>

@optional

- (void)URLConnection:(YUNURLConnection *)connection
      didSendBodyData:(NSInteger)bytesWritten
    totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@end

@interface YUNURLConnection : NSObject

- (YUNURLConnection *)initWithRequest:(NSURLRequest *)request
                    completionHandler:(YUNURLConnectionHandler)handler
NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<YUNURLConnectionDelegate> delegate;

- (void)cancel;
- (void)start;
- (void)setDelegateQueue:(NSOperationQueue *)queue;

@end
