//
//  YUNWebDialog.h
//  YUNNetKit
//
//  Created by Orange on 5/31/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YUNWebDialogDelegate;

@interface YUNWebDialog : NSObject

+ (instancetype)showWithName:(NSString *)name
                  parameters:(NSDictionary *)parameters
                    delegate:(id<YUNWebDialogDelegate>)delegate;

@property (nonatomic, assign) BOOL deferVisibility;
@property (nonatomic, assign) id<YUNWebDialogDelegate> delegate;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDictionary *parameters;

- (BOOL)show;

@end

@protocol YUNWebDialogDelegate <NSObject>

- (void)webDialog:(YUNWebDialog *)webDialog didCompleteWithResults:(NSDictionary *)results;
- (void)webDialog:(YUNWebDialog *)webDialog didFailWithError:(NSError *)error;
- (void)webDialogDidCancel:(YUNWebDialog *)webDialog;

@end