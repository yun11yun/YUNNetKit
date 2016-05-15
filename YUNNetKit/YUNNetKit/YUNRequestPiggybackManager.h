//
//  YUNRequestPiggybackManager.h
//  YUNNetKit
//
//  Created by Orange on 5/13/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUNRequestConnection.h"

@interface YUNRequestPiggybackManager : NSObject

+ (void)addPiggybackRequests:(YUNRequestConnection *)connection;

+ (void)addRefreshPiggyback:(YUNRequestConnection *)connection
          permissionHandler:(YUNRequestHandler)permissionHandler;

+ (void)addRefreshPiggybackIfState:(YUNRequestConnection *)connection;

+ (void)addServerConfigurationPiggyback:(YUNRequestConnection *)connection;

@end
