//
//  YUNRequestConnection.m
//  YUNNetKit
//
//  Created by bit_tea on 16/4/28.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNRequestConnection.h"

#import "YUNContants.h"
#import "YUNError.h"
#import "YUNRequest+Internal.h"
#import "YUNRequestBody.h"
#import "YUNRequestDataAttachment.h"
#import "YUNRequestMetadata.h"
#import "YUNRequestPiggybackManager.h"
#import "YUNInternalUtility.h"
#import "YUNLogger.h"
#import "YUNSettings+Internal.h"
#import "YUNURLConnection.h"
#import "YUNErrorConfiguration.h"
#import "YUNServerConfigurationManager.h"

NSString *const YUNNonJSONResponseProperty = @"YUN11YUN_NON_JSON_RESULT";

// URL construction constants
static NSString *const kURLPrefix = @"graph.";
static NSString *const kVideoURLPrefix = @"graph-video.";

static NSString *const kBatchKey = @"batch";
static NSString *const kBatchMethodKey = @"method";
static NSString *const kBatchRelativeURLKey = @"relative_url";
static NSString *const kBatchAttachmentKey = @"attached_files";
static NSString *const kBatchFileNamePrefix = @"file";
static NSString *const kBatchEntryName = @"name";

static NSString *const kAccessTokenKey = @"access_token";
#if TARGET_OS_TV
static NSString *const kSDK = @"tvos";
static NSString *const kUserAgentBase = @"FBtvOSSDK";
#else
static NSString *const kSDK = @"ios";
static NSString *const kUserAgentBase = @"FBiOSSDK";
#endif

static NSString *const kBatchRestMethodBaseURL = @"method/";

static NSTimeInterval g_defaultTimeout = 60.0;

static YUNErrorConfiguration *g_errorConfiguration;

// -----------------------------------------------------------------------
// YUNRequestConnectionState

typedef NS_ENUM(NSUInteger, YUNRequestConnectionState)
{
    kStateCreated,
    kStateSrialized,
    kStateStarted,
    kStateCompleted,
    kStateCancelled,
};

// -----------------------------------------------------------------------
// Private properties and methods
@interface YUNRequestConnection () <YUNURLConnectionDelegate>

@property (nonatomic, retain) YUNURLConnection *connection;
@property (nonatomic, retain) NSMutableArray *requests;
@property (nonatomic) YUNRequestConnectionState state;
@property (nonatomic, retain) YUNLogger *logger;
@property (nonatomic) unsigned long requestStartTime;

@end

// -----------------------------------------------------------------------
// YUNReqeustConnection

@implementation YUNRequestConnection
{
    NSString *_overrideVersionPart;
    NSUInteger _expectingResults;
    NSOperationQueue *_delegateQueue;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _requests = [[NSMutableArray alloc] init];
        _timeout = g_defaultTimeout;
        _state = kStateCreated;
        _logger = [[YUNLogger alloc] initWithLoggingBehavior:YUNLoggingBehaviorNetworkRequests];
    }
    return self;
}

- (void)dealloc
{
    _connection.delegate = nil;
    [_connection cancel];
}

#pragma mark - Public

+ (void)setDefaultConnectionTimeout:(NSTimeInterval)defaultTimeout
{
    if (defaultTimeout >= 0) {
        g_defaultTimeout = defaultTimeout;
    }
}

- (void)addRequest:(YUNRequest *)request
 completionHandler:(YUNRequestHandler)handler
{
    [self addRequest:request completionHandler:handler batchEntryName:nil];
}

- (void)addRequest:(YUNRequest *)request
 completionHandler:(YUNRequestHandler)handler
    batchEntryName:(NSString *)name
{
    NSDictionary *batchParams = (name) ? @{kBatchEntryName : name} : nil;
    [self addRequest:request completionHandler:handler batchParameters:batchParams];
}

- (void)addRequest:(YUNRequest *)request
 completionHandler:(YUNRequestHandler)handler
   batchParameters:(NSDictionary *)batchParameters
{
    if (self.state != kStateCreated) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Cannot add requests once started or if a URLRequest is set"
                                     userInfo:nil];
    }
    YUNRequestMetadata *metadata = [[YUNRequestMetadata alloc] initWithRequest:request completionHandler:handler batchParameters:batchParameters];
    [self.requests addObject:metadata];
}

- (void)cancel
{
    self.state = kStateCancelled;
    [self.connection cancel];
    self.connection = nil;
}

- (void)overrideVersionPartWith:(NSString *)version
{
    if (![_overrideVersionPart isEqualToString:version]) {
        _overrideVersionPart = [version copy];
    }
}

- (void)start
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_errorConfiguration = [[YUNErrorConfiguration alloc] initWithDictionary:nil];
    });
    //optimistically check for updated server onfiguration;
    g_errorConfiguration = [YUNServerConfigurationManager cachedServerConfiguration].errorConfiguration ?: g_errorConfiguration;
    
    if (self.state != kStateCreated && self.state != kStateSrialized) {
        [YUNLogger singleShotLogEntry:YUNLoggingBehaviorDeveloperErrors
                         formatString:@"YUNRequestConnection cannot be started again."];
        return;
    }
    [YUNRequestPiggybackManager addPiggybackRequests:self];
    
    NSMutableURLRequest *request = [self requestWithBatch:self.requests timeout:_timeout];
    
    self.state = kStateStarted;
    
    [self logRequest:request bodyLength:0 bodyLogger:nil attatchLogger:nil];
    _requestStartTime = [YUNInternalUtility currentTimeInMilliseconds];
    
    YUNURLConnectionHandler handler = ^(YUNURLConnection *connection,
                                        NSError *error,
                                        NSURLResponse *response,
                                        NSData *responseData) {
        [self completeYUNURLConnectionWithResponse:response
                                              data:responseData
                                      networkError:error];
    };
    
    YUNURLConnection *connection = [[YUNURLConnection alloc] initWithRequest:request completionHandler:handler];
    
    if (_delegateQueue) {
        [connection setDelegateQueue:_delegateQueue];
    }
    connection.delegate = self;
    self.connection = connection;
    [connection start];
    
    id<YUNRequestConnectionDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(requestConnectionWillBeginLoading:)]) {
        if (_delegateQueue) {
            [_delegateQueue addOperationWithBlock:^{
                [delegate requestConnectionWillBeginLoading:self];
            }];
        } else {
            [delegate
             requestConnectionWillBeginLoading:self];
        }
    }
}

- (void)setDelegateQueue:(NSOperationQueue *)queue
{
    _delegateQueue = queue;
}

- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout
{
    return nil;
}

#pragma mark - Private methods (request generation)

//
// Adds request data to a batch in a format expected by the JsonWriter.
// Binary attachments are refreshed by ame in JSON and added to the
// attachments dictionary.
//
- (void)addRequest:(YUNRequestMetadata *)metadata
           toBatch:(NSMutableArray *)batch
       attachments:(NSMutableDictionary *)attachments
        batchToken:(NSString *)batchToken
{
    NSMutableDictionary *requestElement = [[NSMutableDictionary alloc] init];
    
    if (metadata.batchParameters) {
        [requestElement addEntriesFromDictionary:metadata.batchParameters];
    }
    
    if (batchToken) {
        metadata.request.parameters[kAccessTokenKey] = batchToken;
        [self registerTokenToOmitFromLog:batchToken];
    }
    
    NSString *urlString = [self urlStringForSingleRequest:metadata.request forBatch:YES];
    requestElement[kBatchRelativeURLKey] = urlString;
    requestElement[kBatchMethodKey] = metadata.request.HTTPMethod;
    
    NSMutableArray *attachmentNames = [NSMutableArray array];
    
    [metadata.request.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([YUNRequest isAttachment:value]) {
            NSString *name = [NSString stringWithFormat:@"%@%lu", kBatchFileNamePrefix,
                              (unsigned long)[attachments count]];
            [attachmentNames addObject:name];
            attachments[name] = value;
        }
    }];
    
    if ([attachmentNames count]) {
        requestElement[kBatchAttachmentKey] = [attachmentNames componentsJoinedByString:@","];
    }
    
    [batch addObject:requestElement];
}

- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(YUNRequestBody *)body
              addFromData:(BOOL)addFormData
                   logger:(YUNLogger *)logger
{
    [attachments enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        value = [YUNInternalUtility convertRequestValue:value];
        if ([value isKindOfClass:[NSString class]]) {
            if (addFormData) {
                [body appendWithKey:key fromValue:value logger:logger];
            }
        } else if ([value isKindOfClass:[UIImage class]]) {
            [body appendWithKey:key imageValue:(UIImage *)value logger:logger];
        } else if ([value isKindOfClass:[NSData class]]) {
            [body appendWithKey:key dataValue:(NSData *)value logger:logger];
        } else if ([value isKindOfClass:[YUNRequestDataAttachment class]]) {
            [body appendWithKey:key dataAttachmentValue:(YUNRequestDataAttachment *)value logger:logger];
        } else {
            [YUNLogger singleShotLogEntry:YUNLoggingBehaviorDeveloperErrors formatString:@"Unsupported YUNRequest attachment:%@, skipping.", value];
        }
    }];
}

//
// Generates a URL for a batch containing only a single request,
// adn names all attachments that need to go in the bogy of the request.
//
// The URL contains all parameters that are not bogy attachments,
// including the session key if present.
//
// Attachments are named and referenced by name in the URL.
//
- (NSString *)urlStringForSingleRequest:(YUNRequest *)request
                               forBatch:(BOOL)forBatch
{
    request.parameters[@"format"] = @"json";
    request.parameters[@"sdk"] = kSDK;
    request.parameters[@"include__headers"] = @"false";
    request.parameters[@"locale"] = [NSLocale currentLocale].localeIdentifier;
    
    return nil;
}

#pragma mark - Private methods (miscellaneous)

- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(YUNLogger *)bogyLogger
     attatchLogger:(YUNLogger *)attachmentLogger
{
    
}

- (void)registerTokenToOmitFromLog:(NSString *)token
{
    if (![[YUNSettings loggingBehavior] containsObject:YUNLoggingBehaviorAccessTokens]) {
        [YUNLogger registerStringToReplace:token replaceWith:@"ACCESS_TOKEN_REMOVED"];
    }
}

#pragma mark - Private methods (response parsing)
- (void)completeYUNURLConnectionWithResponse:(NSURLResponse *)response
                                        data:(NSData *)data
                                networkError:(NSError *)error
{
    
}

@end
