//
//  YUNKeychainStore.h
//  YUNNetKit
//
//  Created by Orange on 5/11/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUNKeychainStore : NSObject

@property (nonatomic, readonly, copy) NSString *service;
@property (nonatomic, readonly, copy) NSString *accessGroup;

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup NS_DESIGNATED_INITIALIZER;

- (BOOL)setDictionary:(NSDictionary *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (NSDictionary *)dictionarayForKey:(NSString *)key;

- (BOOL)setString:(NSString *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (NSString *)stringForKey:(NSString *)key;

- (BOOL)setData:(NSData *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (NSData *)dataForKey:(NSString *)key;

// hook for subclasses to override keychain query construction.
- (NSMutableDictionary *)queryForKey:(NSString *)key;

@end
