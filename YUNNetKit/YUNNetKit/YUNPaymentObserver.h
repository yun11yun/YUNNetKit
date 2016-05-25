//
//  YUNPaymentObserver.h
//  YUNNetKit
//
//  Created by Orange on 5/24/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

// Class to encapsulate implicit logging of purchase events
@interface YUNPaymentObserver : NSObject
+ (void)startObservingTransactions;
+ (void)stopObservingTransactions;
@end
