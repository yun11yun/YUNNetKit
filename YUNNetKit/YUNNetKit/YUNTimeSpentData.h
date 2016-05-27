//
//  YUNTimeSpentData.h
//  YUNNetKit
//
//  Created by Orange on 5/27/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YUNMacros.h"

extern NSString *const YUNTimeSpentFilename;

// Class to encapsulate persisting of time spent data collected by [YUNAppEvents activateApp]. The activate ap App Event is
// logged when restore: is called with sufficient time since the last deactivation.
@interface YUNTimeSpentData : NSObject

+ (void)suspend;
+ (void)restore:(BOOL)calledFromActivateApp;

+ (void)setSourceApplication:(NSString *)sourceApplication openURL:(NSURL *)url;
+ (void)setSourceApplication:(NSString *)sourceApplication isFromAppLink:(BOOL)isFromAppLink;
+ (void)registerAutoResetSourceApplication;

@end
