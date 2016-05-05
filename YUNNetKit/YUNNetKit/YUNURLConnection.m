//
//  YUNURLConnection.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/27.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNURLConnection.h"

#import "YUNInternalUtility.h"
#import "YUNSettings.h"
#import "YUNLogger.h"
#import "YUNMacros.h"

@interface YUNURLConnection () <NSURLConnectionDataDelegate>

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, copy) YUNURLConnectionHandler handler;
@property (nonatomic, retain) NSURLResponse *response;
@property (nonatomic) unsigned long requestStartTime;
@property (nonatomic, readonly) NSUInteger loggerSerialNumber;

@end

@implementation YUNURLConnection

#pragma mark - Lifecycle

- (YUNURLConnection *)initWithRequest:(NSURLRequest *)request
                    completionHandler:(YUNURLConnectionHandler)handler
{
    if ((self = [super init])) {
        _requestStartTime = [YUNInternalUtility currentTimeInMilliseconds];
        _loggerSerialNumber = [YUNLogger generateSerialNumber];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
#pragma clang diagnostic pop
        _data = [[NSMutableData alloc] init];
        _handler = [handler copy];
    }
    return self;
}

- (instancetype)init
{
    YUN_NOT_DESIGNATED_INITIALIZER(initWithRequest:completionHandler:);
    return [self initWithRequest:nil completionHandler:NULL];
}

- (void)logAndInvokeHandler:(YUNURLConnectionHandler)handler
                      error:(NSError *)error {
    if (error) {
        NSString *logEntry = [NSString stringWithFormat:@"YUNURLConnection <# %lu>:\n Error: '%@'\n%@\n",(unsigned long)self.loggerSerialNumber,
                              [error localizedDescription],
                              [error userInfo]];
        [self logMessage:logEntry];
    }
    
    [self invokeHandler:handler error:error response:nil responseData:nil];
}

- (void)logAndInvokeHandler:(YUNURLConnectionHandler)handler
                   response:(NSURLResponse *)response
               responseData:(NSData *)responseData
{
    //Basic YUNURLConnection logging just prints out the URL. YUNGraphRequest logging provides more details.
    NSString *mimeType = [response MIMEType];
    NSMutableString *mutableLogEntry = [NSMutableString stringWithFormat:@"FBSDKURLConnection <#%lu>:\n  Duration: %lu msec\nResponse Size: %lu kB\n  MIME type: %@\n",
                                        (unsigned long)self.loggerSerialNumber,
                                        [YUNInternalUtility currentTimeInMilliseconds] - self.requestStartTime,
                                        (unsigned long)[responseData length] / 1024,
                                        mimeType];
    
    if ([mimeType isEqualToString:@"text/javascript"]) {
        NSString *responseUTF8 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        [mutableLogEntry appendFormat:@"  Response:\n%@\n\n", responseUTF8];
    }
    
    [self logMessage:mutableLogEntry];
    
    [self invokeHandler:handler error:nil response:response responseData:responseData];
}

- (void)invokeHandler:(YUNURLConnectionHandler)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData
{
    if (handler != nil) {
        handler(self, error, response, responseData);
    }
}

- (void)logMessage:(NSString *)message
{
    [YUNLogger singleShotLogEntry:YUNLoggingBehaviorNetworkRequests formatString:@"%@", message];
}

- (void)cancel
{
    [self.connection cancel];
    self.handler = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    [self.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    @try {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorSecureConnectionFailed) {
            NSOperatingSystemVersion iOS9Version = { .majorVersion = 9, .minorVersion = 0, .patchVersion = 0 };
            if ([YUNInternalUtility isOSRunTimeVersionAtLeast:iOS9Version]) {
                [YUNLogger singleShotLogEntry:YUNLoggingBehaviorDeveloperErrors
                                       logEntry:@"WARNING: FBSDK secure network request failed. Please verify you have configured your "
                 "app for Application Transport Security compatibility described at https://developers.facebook.com/docs/ios/ios9"];
            }
        }
        [self logAndInvokeHandler:self.handler error:error];
    } @finally {
        self.handler = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    @try {
        [self logAndInvokeHandler:self.handler response:self.response responseData:self.data];
    } @finally {
        self.handler = nil;
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse {
    return request;
}

- (void)       connection:(NSURLConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    id<YUNURLConnectionDelegate> delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(URLConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [delegate         URLConnection:self
                        didSendBodyData:bytesWritten
                      totalBytesWritten:totalBytesWritten
              totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)start
{
    [_connection start];
}

- (void)setDelegateQueue:(NSOperationQueue*)queue
{
    [_connection setDelegateQueue:queue];
}

@end
