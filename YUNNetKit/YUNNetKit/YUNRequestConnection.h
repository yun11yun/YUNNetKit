//
//  YUNRequestConnection.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YUNRequest;
@class YUNRequestConnection;

/*!
 @typedef YUNRequestHandler
 
 @abstract
 A block that is passed to addRequest to register for a callback with the results of that
 request once the connection completes.
 
 @discussion
 Pass a block of this type when calling addRequest.  This will be called once
 the request completes.  The call occurs on the UI thread.
 
 @param connection      The `FBSDKGraphRequestConnection` that sent the request.
 
 @param result          The result of the request.  This is a translation of
 JSON data to `NSDictionary` and `NSArray` objects.  This
 is nil if there was an error.
 
 @param error           The `NSError` representing any error that occurred.
 
 */
typedef void (^YUNRequestHandler)(YUNRequestConnection *connection,
                                  id result,
                                  NSError *error);

/**
 *  @protocol
 *  
 *  @abstract
    The 'YUNRequestConnectionDelegate' protocol defines the methods used to receive network
    activity progress information from a <YUNRequestConnection>.
 */
@protocol YUNRequestConnectionDelegate <NSObject>

@optional
/*!
 @method
 
 @abstract
 Tells the delegate the request connection will begin loading
 
 @discussion
 If the <YUNRequestConnection> is created using one of the convenience factory methods prefixed with
 start, the object returned from the convenience method has already begun loading and this method
 will not be called when the delegate is set.
 
 @param connection    The request connection that is starting a network request
 */
- (void)requestConnectionWillBeginLoading:(YUNRequestConnection *)connection;

/*!
 @method
 
 @abstract
 Tells the delegate the request connection finished loading
 
 @discussion
 If the request connection completes without a network error occuring then this method is called.
 Invocation of this method does not indicate success of every <YUNRequest> made, only that the
 request connection has no further activity. Use the error argument passed to the YUNRequestHandler
 block to determine success or failure of each <YUNRequest>.
 
 This method is invoked after the completion handler for each <YUNRequest>.
 
 @param connection    The request connection that successfully completed a network request
 */
- (void)requestConnectionDidFinishLoading:(YUNRequestConnection *)connection;

/*!
 @method
 
 @abstract
 Tells the delegate the request connection failed with an error
 
 @discussion
 If the request connection fails with a network error then this method is called. The `error`
 argument specifies why the network connection failed. The `NSError` object passed to the
 YUNRequestHandler block may contain additional information.
 
 @param connection    The request connection that successfully completed a network request
 @param error         The `NSError` representing the network error that occurred, if any. May be nil
 in some circumstances. Consult the `NSError` for the <YUNRequest> for reliable
 failure information.
 */
- (void)requestConnection:(YUNRequestConnection *)connection
         didFailWithError:(NSError *)error;

/*!
 @method
 
 @abstract
 Tells the delegate how much data has been sent and is planned to send to the remote host
 
 @discussion
 The byte count arguments refer to the aggregated <YUNRequest> objects, not a particular <YUNRequest>.
 
 Like `NSURLConnection`, the values may change in unexpected ways if data needs to be resent.
 
 @param connection                The request connection transmitting data to a remote host
 @param bytesWritten              The number of bytes sent in the last transmission
 @param totalBytesWritten         The total number of bytes sent to the remote host
 @param totalBytesExpectedToWrite The total number of bytes expected to send to the remote host
 */
- (void)requestConnection:(YUNRequestConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@end

/*!
 @class YUNRequestConnection
 
 @abstract
 The `YUNRequestConnection` represents a single connection to Facebook to service a request.
 
 @discussion
 The request settings are encapsulated in a reusable <YUNRequest> object. The
 `YUNRequestConnection` object encapsulates the concerns of a single communication
 e.g. starting a connection, canceling a connection, or batching requests.
 
 */
@interface YUNRequestConnection : NSObject

/**
 *  The delegate object that receives updates.
 */
@property (nonatomic, assign) id<YUNRequestConnectionDelegate> delegate;

/**
 *  Gets or sets the timeout interval to wait for a response before giving up.
 */
@property (nonatomic) NSTimeInterval timeout;

/*!
 @abstract
 The raw response that was returned from the server.  (readonly)
 
 @discussion
 This property can be used to inspect HTTP headers that were returned from
 the server.
 
 The property is nil until the request completes.  If there was a response
 then this property will be non-nil during the YUNRequestHandler callback.
 */
@property (nonatomic, retain, readonly) NSHTTPURLResponse *URLResponse;


/*!
 @methodgroup Class methods
 */

/*!
 @method
 
 @abstract
 This method sets the default timeout on all YUNRequestConnection instances. Defaults to 60 seconds.
 
 @param defaultConnectionTimeout     The timeout interval.
 */
+ (void)setDefaultConnectionTimeout:(NSTimeInterval)defaultConnectionTimeout;

/*!
 @methodgroup Adding requests
 */

/*!
 @method
 
 @abstract
 This method adds an <YUNRequest> object to this connection.
 
 @param request       A request to be included in the round-trip when start is called.
 @param handler       A handler to call back when the round-trip completes or times out.
 
 @discussion
 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection.
 */
- (void)addRequest:(YUNRequest *)request
 completionHandler:(YUNRequestHandler)handler;

/*!
 @method
 
 @abstract
 This method adds an <YUNRequest> object to this connection.
 
 @param request         A request to be included in the round-trip when start is called.
 
 @param handler         A handler to call back when the round-trip completes or times out.
 The handler will be invoked on the main thread.
 
 @param name            An optional name for this request.  This can be used to feed
 the results of one request to the input of another <YUNRequest> in the same
 `YUNRequestConnection` as described
 
 @discussion
 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection. This request can be named
 to allow for using the request's response in a subsequent request.
 */
- (void)addRequest:(YUNRequest *)request
 completionHandler:(YUNRequestHandler)handler
    batchEntryName:(NSString *)name;

/*!
 @method
 
 @abstract
 This method adds an <YUNRequest> object to this connection.
 
 @param request         A request to be included in the round-trip when start is called.
 
 @param handler         A handler to call back when the round-trip completes or times out.
 
 @param batchParameters The optional dictionary of parameters to include for this request
 as described
 Examples include "depends_on", "name", or "omit_response_on_success".
 
 @discussion
 The completion handler is retained until the block is called upon the
 completion or cancellation of the connection. This request can be named
 to allow for using the request's response in a subsequent request.
 */
- (void)addRequest:(YUNRequest *)request
 completionHandler:(YUNRequestHandler)handler
   batchParameters:(NSDictionary *)batchParameters;

/*!
 @methodgroup Instance methods
 */

/*!
 @method
 
 @abstract
 Signals that a connection should be logically terminated as the
 application is no longer interested in a response.
 
 @discussion
 Synchronously calls any handlers indicating the request was cancelled. Cancel
 does not guarantee that the request-related processing will cease. It
 does promise that  all handlers will complete before the cancel returns. A call to
 cancel prior to a start implies a cancellation of all requests associated
 with the connection.
 */
- (void)cancel;

/*!
 @method
 
 @abstract
 This method starts a connection with the server and is capable of handling all of the
 requests that were added to the connection.
 
 @discussion By default, a connection is scheduled on the current thread in the default mode when it is created.
 See `setDelegateQueue:` for other options.
 
 This method cannot be called twice for an `FBSDKGraphRequestConnection` instance.
 */
- (void)start;

/*!
 @abstract Determines the operation queue that is used to call methods on the connection's delegate.
 @param queue The operation queue to use when calling delegate methods.
 @discussion By default, a connection is scheduled on the current thread in the default mode when it is created.
 You cannot reschedule a connection after it has started.
 
 This is very similar to `[NSURLConnection setDelegateQueue:]`.
 */
- (void)setDelegateQueue:(NSOperationQueue *)queue;

/*!
 @method
 
 @abstract
 Overrides the default version for a batch request
 
 @discussion
 The SDK automatically prepends a version part, such as "v2.0" to API paths in order to simplify API versioning
 for applications. If you want to override the version part while using batch requests on the connection, call
 this method to set the version for the batch request.
 
 @param version   This is a string in the form @"v2.0" which will be used for the version part of an API path
 */
- (void)overrideVersionPartWith:(NSString *)version;

@end
