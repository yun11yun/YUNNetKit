//
//  YUNUtility.h
//  YUNNetKit
//
//  Created by Orange on 5/5/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 @abstract Class to contain common uitlity methods.
 */
@interface YUNUtility : NSObject

/**
 *  Parses a query string into a dictionary.
 *
 *  @param queryString The query string value.
 *
 *  @return A dictionary with the key/value pairs.
 */
+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString;

/**
 *  Constructs a query string from a dictionary.
 *
 *  @param dictionry The dictionary with key/value pairs for the query string.
 *  @param errorRef  If error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return Query string representation of the parameters.
 */
+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionry error:(NSError *__autoreleasing *)errorRef;

/**
 *  Decodes a value from an URL
 *
 *  @param value The value to decode.
 *
 *  @return The decoded value.
 */
+ (NSString *)URLDecode:(NSString *)value;

/**
 *  Encodes a value for an URL
 *
 *  @param value The value to encode
 *
 *  @return The encoded value.
 */
+ (NSString *)URLEncode:(NSString *)value;

@end
