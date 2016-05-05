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

@interface YUNRequestConnection : NSObject

@end
