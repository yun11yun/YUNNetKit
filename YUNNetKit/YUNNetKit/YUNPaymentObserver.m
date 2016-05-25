//
//  YUNPaymentObserver.m
//  YUNNetKit
//
//  Created by Orange on 5/24/16.
//  Copyright © 2016 bit_tea. All rights reserved.
//

#import "YUNPaymentObserver.h"

#import <StoreKit/StoreKit.h>

#import "YUNAppEvents+Internal.h"
#import "YUNDynamicFrameworkLoader.h"
#import "YUNLogger.h"
#import "YUNSettings.h"

static NSString *const YUNAppEventParameterImplicitlyLoggerPurchase = @"_implicitlyLoggedPurchaseEvent";
static NSString *const YUNAppEventNamePurchaseFailed = @"yun_mobile_purchase_failed";
static NSString *const YUNAppEventParameterNameProductTitle = @"yun_content_title";
static NSString *const YUNAppEventParameterNameTransactionID = @"yun_transaction_id";
static int const YUNMaxParameterValueLength = 100;
static NSMutableArray *g_pendingRequestors;

@interface YUNPaymentProductRequestor : NSObject <SKProductsRequestDelegate>
@property (nonatomic, retain) SKPaymentTransaction *transaction;

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction;
- (void)resolveProducts;

@end

@interface YUNPaymentObserver() <SKPaymentTransactionObserver>
@end

@implementation YUNPaymentObserver
{
    BOOL _observingTransactions;
}

+ (void)startObservingTransactions
{
    [[self singleton] startObservingTransactions];
}


+ (void)stopObservingTransactions
{
    [[self singleton] stopObservingTransactions];
}

#pragma mark - Internal methods

+ (YUNPaymentObserver *)singleton
{
    static YUNPaymentObserver *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[YUNPaymentObserver alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observingTransactions = NO;
    }
    return self;
}

- (void)startObservingTransactions
{
    @synchronized(self) {
        if (!_observingTransactions) {
            [(SKPaymentQueue *)[yundfl_SKPaymentQueueClass() defaultQueue] addTransactionObserver:self];
            _observingTransactions = YES;
        }
    }
}

- (void)stopObservingTransactions
{
    @synchronized(self) {
        if (_observingTransactions) {
            [(SKPaymentQueue *)[yundfl_SKPaymentQueueClass() defaultQueue] removeTransactionObserver:self];
            _observingTransactions = NO;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateFailed:
                [self handleTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
            case SKPaymentTransactionStateRestored:
                break;
        }
    }
}

- (void)handleTransaction:(SKPaymentTransaction *)transaction
{
    YUNPaymentProductRequestor *productRequest = [[YUNPaymentProductRequestor alloc] initWithTransaction:transaction];
    [productRequest resolveProducts];
}

@end

@interface YUNPaymentProductRequestor ()
@property (nonatomic, retain) SKProductsRequest *productReqeust;
@end

@implementation YUNPaymentProductRequestor

+ (void)initialize
{
    if ([self class] == [YUNPaymentProductRequestor class]) {
        g_pendingRequestors = [[NSMutableArray alloc] init];
    }
}

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction
{
    self = [super init];
    if (self) {
        _transaction = transaction;
    }
    return self;
}

- (void)setProductReqeust:(SKProductsRequest *)productReqeust
{
    if (productReqeust != _productReqeust) {
        if (_productReqeust) {
            _productReqeust.delegate = nil;
        }
        _productReqeust = productReqeust;
    }
}

- (void)resolveProducts
{
    NSString *productId = self.transaction.payment.productIdentifier;
    NSSet *productIdentifiers = [NSSet setWithObjects:productId, nil];
    self.productReqeust = [[yundfl_SKProductsRequestClass() alloc] initWithProductIdentifiers:productIdentifiers];
    self.productReqeust.delegate = self;
    @synchronized(g_pendingRequestors) {
        [g_pendingRequestors addObject:self];
    }
    [self.productReqeust start];
}

@end
