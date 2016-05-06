//
//  YUNServerConfigurationManager+Internal.h
//  YUNNetKit
//
//  Created by Orange on 5/6/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNServerConfigurationManager.h"

@class YUNRequest;

@interface YUNServerConfigurationManager ()

+ (void)processLoadRequestResponse:(id)result error:(NSError *)error appID:(NSString *)appID;

+ (YUNRequest *)requestToLoadServerConfiguration:(NSString *)appID;

@end
