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
// Serializes all requests in the batch to JSON and appends the result to
// body. Also names all attachments that need to go as separate blocks in
// the body of the request.
//
// All the requests are serialized into JSON, with any binary attachments
// named and referenced by name in the JSON.
//
- (void)appendJSONRequests:(NSArray *)requests
                    toBody:(YUNRequestBody *)body
        andNameAttachments:(NSMutableDictionary *)attachments
                    logger:(YUNLogger *)logger
{
    NSMutableArray *batch = [[NSMutableArray alloc] init];
    NSString *batchToken = nil;
    for (YUNRequestMetadata *metadata in requests) {
        NSString *individualToken = [self accessTokenWithRequest:metadata.request];
        BOOL isClientToken = [YUNSettings clientToken] &&
        [individualToken hasPrefix:[YUNSettings clientToken]];
        if (!batchToken &&
            !isClientToken) {
            batchToken = individualToken;
        }
        [self addRequest:metadata
                 toBatch:batch
             attachments:attachments
              batchToken:[batchToken isEqualToString:individualToken] ? nil : individualToken];
    }
    
    NSString *jsonBatch = [YUNInternalUtility JSONStringForObject:batch error:NULL invalidObjectHandler:NULL];
    
    [body appendWithKey:kBatchKey fromValue:jsonBatch logger:logger];
    if (batchToken) {
        [body appendWithKey:kBatchKey fromValue:batchToken logger:logger];
    }
}

// Validate that all GET requests after v2.4 have a "fields" param
- (void)_validateFieldsParamForGetRequests:(NSArray *)requests
{
    for (YUNRequestMetadata *metadata in requests) {
        YUNRequest *request = metadata.request;
        if ([request.HTTPMethod.uppercaseString isEqualToString:@"GET"] &&
            request.parameters[@"fields"] &&
            [request.path rangeOfString:@"fields="].location == NSNotFound) {
            [YUNLogger singleShotLogEntry:YUNLoggingBehaviorDeveloperErrors
                             formatString:@"starting with API v2.4,GET requests for /%@ should contain an explicit \"fields\" parameters", request.path];
        }
    }
}

//
// Generaates a NSURLRequest based on the contents of self.requests, and sets
// options on the request. Chooses betwooen URL_based request for a single
// request and JSON-based request for batches.
- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout
{
    YUNRequestBody *body = [[YUNRequestBody alloc] init];
    YUNLogger *bodyLogger = [[YUNLogger alloc] initWithLoggingBehavior:_logger.loggingBehavior];
    YUNLogger *attachmentLogger = [[YUNLogger alloc] initWithLoggingBehavior:_logger.loggingBehavior];
    
    NSMutableURLRequest *request;
    
    if (requests.count == 0) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                reason:@"YUNRequestConnection: Must have at least one request or urlRequest not specified."
                              userInfo:nil]
         raise];
    }
    
    [self _validateFieldsParamForGetRequests:requests];
    
    if ([requests count] == 1) {
        YUNRequestMetadata *metadata = [requests objectAtIndex:0];
        NSURL *url = [NSURL URLWithString:[self urlStringForSingleRequest:metadata.request forBatch:NO]];
        request = [NSMutableURLRequest requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:timeout];
        
        // HTTP methods aare case-sensitive; be helpful in case someone provided a mixed case one.
        NSString *httpMethod = [metadata.request.HTTPMethod uppercaseString];
        [request setHTTPMethod:httpMethod];
        [self appendAttachments:metadata.request.parameters
                         toBody:body
                    addFromData:[httpMethod isEqualToString:@"POST"]
                         logger:attachmentLogger];
    } else {
        // Find the session with an app ID and use that as the batch_app_id. If we can't
        // find one, try to load it from the plist. As a last resort, pass 0.
        NSString *batchAppID = [YUNSettings appID];
        if (!batchAppID || batchAppID.length) {
            // The API batch method requires either an access token or batch_app_id.
            // If we can't determine an App ID to use for the batch, we can't issue it.
            [[NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:@"YUNRequestConnection: [YUNSettings appID] must be specified for batch requests"
                                   userInfo:nil]
             raise];

        }
        [body appendWithKey:@"batch_app_id" fromValue:batchAppID logger:bodyLogger];
        
        NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
        
        [self appendJSONRequests:requests
                          toBody:body
              andNameAttachments:attachments
                          logger:bodyLogger];
        
        [self appendAttachments:attachments
                         toBody:body
                    addFromData:NO
                         logger:attachmentLogger];
        NSURL *url = [YUNInternalUtility ]
    }
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

- (NSString *)accessTokenWithRequest:(YUNRequest *)request
{
    NSString *token = request.tokenString ?: request.parameters[kAccessTokenKey];
    if (!token && !(request.flags & YUNRequestFlagSkipClientToken && [YUNSettings clientToken].length > 0)) {
        return [NSString stringWithFormat:@"%@|%@", [YUNSettings appID], [YUNSettings clientToken]];
    }
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
