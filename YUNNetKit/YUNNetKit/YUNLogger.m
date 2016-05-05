//
//  YUNLogger.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/27.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNLogger.h"

#import "YUNInternalUtility.h"
#import "YUNSettings+Internal.h"

static NSUInteger g_serialNumberCounter = 1111;
static NSMutableDictionary *g_stringsToReplace = nil;
static NSMutableDictionary *g_startTimesWithTags = nil;

@interface YUNLogger ()

@property (nonatomic, strong, readonly) NSMutableString *internalContents;

@end

@implementation YUNLogger

// Lifetime

- (instancetype)initWithLoggingBehavior:(NSString *)logginBehavior
{
    if ((self = [super init])) {
#warning setup isActive
        _loggingBehavior = logginBehavior;
        if (_isActive) {
            _internalContents = [[NSMutableString alloc] init];
            _loggerSerialNumber = [YUNLogger generateSerialNumber];
        }
    }
    return self;
}

// Public properties

- (NSString *)contents
{
    return _internalContents;
}

- (void)setContents:(NSString *)contents
{
    if (_isActive) {
        _internalContents = [NSMutableString stringWithString:contents];
    }
}

// Public properties

- (void)appendString:(NSString *)string
{
    if (_isActive) {
        [_internalContents appendString:string];
    }
}

- (void)appendFormat:(NSString *)formatString, ...
{
    if (_isActive) {
        va_list vaArguments;
        va_start(vaArguments, formatString);
        NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaArguments];
        va_end(vaArguments);
        
        [self appendString:logString];
    }
}

- (void)appendKey:(NSString *)key value:(NSString *)value
{
    if (_isActive && [value length]) {
        [_internalContents appendFormat:@"  %@:\t%@\n", key, value];
    }
}

- (void)emitToNSLog
{
    if (_isActive) {
        for (NSString *key in [g_stringsToReplace keyEnumerator]) {
            [_internalContents replaceOccurrencesOfString:key
                                               withString:[g_stringsToReplace objectForKey:key]
                                                  options:NSLiteralSearch
                                                    range:NSMakeRange(0, [_internalContents length])];
        }
        const int MAX_LOG_STRING_LENGTH = 10000;
        NSString *logString = _internalContents;
        if (_internalContents.length > MAX_LOG_STRING_LENGTH) {
            logString = [NSString stringWithFormat:@"TRUNCATED: %@", [_internalContents substringFromIndex:MAX_LOG_STRING_LENGTH]];
        }
        NSLog(@"YUNLOG: %@", logString);
        
        [_internalContents setString:@""];
    }
}

// Public static methods

+ (NSUInteger)generateSerialNumber
{
    return g_serialNumberCounter++;
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior logEntry:(NSString *)logEntry
{
    if ([[YUNSettings loggingBehavior] containsObject:loggingBehavior]) {
        YUNLogger *logger = [[YUNLogger alloc] initWithLoggingBehavior:loggingBehavior];
        [logger appendString:logEntry];
        [logger emitToNSLog];
    }
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior formatString:(NSString *)formatString, ...
{
    if ([[YUNSettings loggingBehavior] containsObject:loggingBehavior]) {
        va_list vaAgruments;
        va_start(vaAgruments, formatString);
        NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaAgruments];
        va_end(vaAgruments);
        
        [self singleShotLogEntry:loggingBehavior logEntry:logString];
    }
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior timestampTag:(NSObject *)timestampTag formatString:(NSString *)formatString, ...
{
    if ([[YUNSettings loggingBehavior] containsObject:loggingBehavior]) {
        va_list vaArguments;
        va_start(vaArguments, formatString);
        NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaArguments];
        va_end(vaArguments);
        
        // Start time of this "timestampTag" is stashed in the dictionary.
        // Treat the incoming object tag simply as an address, since it's only used to identify during lifetime.
        // If we send in as an object, the dictionary will try to copy it.
        NSNumber *tagAsNumber = [NSNumber numberWithUnsignedLong:(unsigned long)(__bridge void *)timestampTag];
        NSNumber *startTimeNumber = [g_startTimesWithTags objectForKey:tagAsNumber];
        
        // Only log if there's been an associated start time.
        if (startTimeNumber) {
            unsigned long elasped = [YUNInternalUtility currentTimeInMilliseconds] - startTimeNumber.unsignedLongValue;
            [g_startTimesWithTags removeObjectForKey:tagAsNumber]; // served its purpose, remove
            
            //Log string is appended with "%d msec", with nothing intervening. This gives the most control to the caller.
            logString = [NSString stringWithFormat:@"%@%lu msec", logString, elasped];
            
            [self singleShotLogEntry:loggingBehavior logEntry:logString];
        }
    }
}

+ (void)registerCurrentTime:(NSString *)loggingBehavior
                    withTag:(NSObject *)timestampTag
{
    if ([[YUNSettings loggingBehavior] containsObject:loggingBehavior]) {
        if (!g_startTimesWithTags) {
            g_startTimesWithTags = [NSMutableDictionary dictionary];
        }
        
        if (g_startTimesWithTags.count >= 1000) {
            [YUNLogger singleShotLogEntry:YUNLoggingBehaviorDeveloperErrors logEntry:@"Unexpectedly large number of outstanding perf logging start times, something is likely wrong."];
        }
        
        unsigned long currTime = [YUNInternalUtility currentTimeInMilliseconds];
        
        // Treat the incoming object tag simply as an address, since it's only used to identify during lifetime.  If
        // we send in as an object, the dictionary will try to copy it.
        unsigned long tagAsNumber = (unsigned long)(__bridge void *)timestampTag;
        [g_startTimesWithTags setObject:[NSNumber numberWithUnsignedLong:currTime]
                                 forKey:[NSNumber numberWithUnsignedLong:tagAsNumber]];
    }
}

+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith {
    
    // Strings sent in here never get cleaned up, but that's OK, don't ever expect too many.
    
    if ([[YUNSettings loggingBehavior] count] > 0) {  // otherwise there's no logging.
        
        if (!g_stringsToReplace) {
            g_stringsToReplace = [[NSMutableDictionary alloc] init];
        }
        
        [g_stringsToReplace setValue:replaceWith forKey:replace];
    }
}

@end
