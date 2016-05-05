//
//  YUNLogger.h
//  YUNNetKit
//
//  Created by bit_tea on 16/4/27.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class YUNLogger
 
 @abstract
 Simple logging utility for conditionally logging strings and then emitting them
 via NSLog().
 
 @unsorted
 */
@interface YUNLogger : NSObject

// Access current accumulated contents of the logger.
@property (nonatomic, copy) NSString *contents;

// Each YUNLogger gets a unique serial number to allow the client to log these numbers and, for instance, correlation of Request/Response
@property (nonatomic, readonly) NSUInteger loggerSerialNumber;

// The logging behavior of this logger. See the YUN_LOG_BEHAVIOR* contants.
@property (nonatomic, copy, readonly) NSString *loggingBehavior;

// Is the current logger instance active, based on its loggingBehavior.
@property (nonatomic, readonly) BOOL isActive;

//
// Instance methods
//

// Create with specified logging behavior
- (instancetype)initWithLoggingBehavior:(NSString *)logginBehavior;

// Append string, or key/value pair
- (void)appendString:(NSString *)string;
- (void)appendFormat:(NSString *)formatString,... NS_FORMAT_FUNCTION(1, 2);
- (void)appendKey:(NSString *)key value:(NSString *)value;

// Emit log, clearing out the logger contents.
- (void)emitToNSLog;

//
// Class methods
//

//
// Return a globally unique serial number to be used for correlating multiple output from the same logger.
//
+ (NSUInteger)generateSerialNumber;

// Simple helper to write a single log entry, based upon whether the behavior matches a specified on.
+ (void)singleShotLogEntry:(NSString *)loggingBehavior
                  logEntry:(NSString *)logEntry;

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              formatString:(NSString *)formatString, ... NS_FORMAT_FUNCTION(2,3);

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              timestampTag:(NSObject *)timestampTag
              formatString:(NSString *)formatString, ... NS_FORMAT_FUNCTION(3,4);

// Register a timestamp label with the "current" time, to then be retrieved by singleShotLogEntry
// to include a duration.
+ (void)registerCurrentTime:(NSString *)loggingBehavior
                    withTag:(NSObject *)timestampTag;

// When logging strings, replace all instances of 'replace' with instances of 'replaceWith'.
+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith;

@end
