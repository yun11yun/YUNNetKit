//
//  YUNKeychainStoreViaBundleID.h
//  YUNNetKit
//
//  Created by Orange on 5/13/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNKeychainStore.h"

// This is the keychainstore defined in 3.17 that incorrectly used the bundle id as the service id
// and should NOT be used outside of this cache.
@interface YUNKeychainStoreViaBundleID : YUNKeychainStore

// since this subclass represents the old keychainstore behavior,
// the designated initializer is just the 'init'.
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end
