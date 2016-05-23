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
#import "YUNTypeUtility.h"
#import "YUNErrorRecoveryAttempter.h"

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
        NSURL *url = [YUNInternalUtility URLWithHostPrefix:kURLPrefix path:nil queryParameters:nil defaultVersion:_overrideVersionPart error:NULL];
        request = [NSMutableURLRequest requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:timeout];
        [request setHTTPMethod:@"POST"];
    }
    
    [request setHTTPBody:[body data]];
    NSUInteger bodyLength = [[body data] length] / 1024;
    
    [request setValue:[YUNRequestConnection userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[YUNRequestBody mimeContentType] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPShouldHandleCookies:NO];
    
    [self logRequest:request bodyLength:bodyLength bodyLogger:bodyLogger attatchLogger:attachmentLogger];
    
    return request;
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
    
    NSString *baseURL;
    if (forBatch) {
        baseURL = request.path;
    } else {
        NSString *token = [self accessTokenWithRequest:request];
        if (token) {
            [request.parameters setValue:token forKey:kAccessTokenKey];
            [self registerTokenToOmitFromLog:token];
        }
        
        NSString *prefix = kURLPrefix;
        // We sepcial case a post to <id>/videos and send it to network
        // We only do this for non batch post requests
        NSString *path = [request.path lowercaseString];
        if ([[request.HTTPMethod uppercaseString] isEqualToString:@"POST"] &&
            [path hasSuffix:@"/videos"]) {
            path = [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            NSArray *components = [path componentsSeparatedByString:@"/"];
            if ([components count] == 2) {
                prefix = kVideoURLPrefix;
            }
        }
        
        baseURL = [[YUNInternalUtility URLWithHostPrefix:prefix path:request.path queryParameters:nil defaultVersion:nil error:NULL] absoluteString];
    }
    
    NSString *url = [YUNRequest serializeURL:baseURL
                                      params:request.parameters
                                  httpMethod:request.HTTPMethod];
    return url;
}

#pragma mark - Private methods (response parsing)
- (void)completeYUNURLConnectionWithResponse:(NSURLResponse *)response
                                        data:(NSData *)data
                                networkError:(NSError *)error
{
    if (self.state != kStateCancelled) {
        NSAssert(self.state == kStateStarted, @"Unexpected state %lu in completeWithResponse", (unsigned long)self.state);
        self.state = kStateCompleted;
    }
    
    NSArray *results = nil;
    _URLResponse = (NSHTTPURLResponse *)response;
    if (response) {
        NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
                 @"Expected NSHTTPURLResponse, got %@",
                 response);
        
        NSInteger statusCode = _URLResponse.statusCode;
        
        if (!error && [response.MIMEType hasPrefix:@"image"]) {
            error = [YUNError errorWithCode:YUNRequestNotTextMimeTypeReturnedErrorCode
                                    message:@"Response is a non-text MIME type; endpoints that return images and other "
                     @"binary data should be fetched using NSURLRequest and NSURLConnection"];
        } else {
            results = [self parseJSONReponse:data
                                       error:&error
                                  statusCode:statusCode];
        }
    } else if (!error) {
        error = [YUNError errorWithCode:YUNUnknownErrorCode
                                message:@"Missing NSURLResponse"];
    }
    
    if (!error) {
        if ([self.requests count] != [results count]) {
            error = [YUNError errorWithCode:YUNRequestProtocolMismatchErrorCode
                                    message:@"Unexpected number of results returned form server."];
        } else {
            [_logger appendFormat:@"Response <#%lu>\nDuration: %lu msec\nSize:%lu kB\nResponse Body:\n%@\n\n",
             (unsigned long)[_logger loggerSerialNumber],
             [YUNInternalUtility currentTimeInMilliseconds] - _requestStartTime,
             (unsigned long)[data length],
             results];
        }
    }
    
    if (error) {
        [_logger appendFormat:@"Response <#%lu> <Error>:\n%@\n%@\n",
         (unsigned long)[_logger loggerSerialNumber],
         [error localizedDescription],
         [error userInfo]];
    }
    [_logger emitToNSLog];
    
    [self coompleteWithResults:results networkError:error];
    
    self.connection = nil;
}

//
// If there is one request, the JSON is the response.
// If there are multiple requests, the JSON has an array of dictionaries whose
// body property is the response.
//   [{ "code":200,
//      "body":"JSON-response-as-a-string" },
//    { "code":200,
//      "body":"JSON-response-as-a-string" }]
//
// In both cases, this function returns an NSArray containing the results.
// The NSArray looks just like the multiple request case except the body
// value is converted from a string to parsed JSON.
//
- (NSArray *)parseJSONReponse:(NSData *)data
                        error:(NSError **)error
                   statusCode:(NSInteger)statusCode;
{
    // API can return "true" or "false", which is not valid JSON.
    // Translate that before asking JSON parser to look at it.
    NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    id response = [self parseJSONOrOtherwise:responseUTF8 error:error];
    
    if (responseUTF8 == nil) {
        NSString *base64Data = [data length] != 0 ? [data base64EncodedStringWithOptions:0] : @"";
        if (base64Data != nil) {
            
#warning YUNAppEvents
        }
    }
    
    NSDictionary *responseError = nil;
    if (!response) {
        if ((error != NULL) && (*error == nil)) {
            *error = [self errorWithCode:YUNUnknownErrorCode
                              statusCode:statusCode
                      parsedJSONResponse:nil
                              innerError:nil
                                 message:@"The server returned an unexpected response."];
        }
    } else if ([self.requests count] == 1) {
        // response is the entry, so put it in a dictioanry under "body" and add
        // that to array of responses.
        [results addObject:@{
                             @"code" : @(statusCode),
                             @"body" : response,
                             }];
    } else if ([response isKindOfClass:[NSArray class]]) {
        // reponse is the array of responses, but the body element of each needs
        // to be decoded from JSON.
        for (id item in response) {
            // Don't let errors parsing one response stop us from parsing another.
            NSError *batchResultError = nil;
            if (![item isKindOfClass:[NSDictionary class]]) {
                [results addObject:item];
            } else {
                NSMutableDictionary *result = [((NSDictionary *)item) mutableCopy];
                if (result[@"body"]) {
                    result[@"body"] = [self parseJSONOrOtherwise:result[@"body"] error:&batchResultError];
                }
                [results addObject:result];
            }
            if (batchResultError) {
                // We'll report back the last error we saw.
                *error = batchResultError;
            }
        }
    } else if ([response isKindOfClass:[NSDictionary class]] &&
               (responseError = [YUNTypeUtility dictionaryValue:response[@"error"]]) != nil &&
               [responseError[@"type"] isEqualToString:@"OAuthException"]) {
        // if there was one request then return the only result. if there were multiple requests
        // but only one error then server rejected the baatch access token
        NSDictionary *result = @{
                                 @"code" : @(statusCode),
                                 @"body" : response,
                                 };
        
        for (NSUInteger resultIndex = 0, resultCount = self.requests.count; resultIndex < resultCount; ++resultIndex) {
            [results addObject:result];
        }
    } else if (error != NULL) {
        *error = [self errorWithCode:YUNRequestProtocolMismatchErrorCode
                          statusCode:statusCode
                  parsedJSONResponse:results
                          innerError:nil
                             message:nil];
    }
    
    return results;
}

- (id)parseJSONOrOtherwise:(NSString *)utf8
                     error:(NSError **)error
{
    id parsed = nil;
    if (!(*error)) {
        parsed = [YUNInternalUtility objectForJSONString:utf8 error:error];
        // if we fail parse we attemp a reparse of a modified input to support results in the form "foo-bar", "true", etc.
        // which is shouldn't be necessary since API v2.1
        if (*error) {
            // we round-trip our hand-wired response through the parser in order to remain
            // consistent with the rest of the output of this function (note, if perf turns out
            // to be a problem -- unlikely -- we can return the following dictionary outright)
            NSDictionary *original = @{YUNNonJSONResponseProperty : utf8};
            NSString *jsonrep = [YUNInternalUtility JSONStringForObject:original error:NULL invalidObjectHandler:NULL];
            NSError *reparseError = nil;
            parsed = [YUNInternalUtility objectForJSONString:jsonrep error:&reparseError];
            if (!reparseError) {
                *error = nil;
            }
        }
    }
    return parsed;
}

- (void)coompleteWithResults:(NSArray *)results
                networkError:(NSError *)networkError
{
    NSUInteger count = [self.requests count];
    _expectingResults = count;
    NSUInteger disabledRecoveryCount = 0;
    for (YUNRequestMetadata *metadata in self.requests) {
        if ([metadata.request isGraphErrorRecoveryDisabled]) {
            disabledRecoveryCount++;
        }
    }
    
    [self.requests enumerateObjectsUsingBlock:^(YUNRequestMetadata *metadata, NSUInteger idx, BOOL *stop) {
        id result = networkError ? nil : [results objectAtIndex:idx];
        NSError *resultError = networkError ?: [self errorFromResult:result request:metadata.request];
        
        id body = nil;
        if (!resultError && [result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resultDictionary = [YUNTypeUtility dictionaryValue:result];
            body = [YUNTypeUtility dictionaryValue:resultDictionary[@"body"]];
        }
        
        [self processResultBody:body error:resultError metadata:metadata canNotifyDelegate:(networkError ? NO : YES)];
    }];
    
    if (networkError) {
        if ([_delegate respondsToSelector:@selector(requestConnection:didFailWithError:)]) {
            [_delegate requestConnection:self didFailWithError:networkError];
        }
    }
}

- (void)processResultBody:(NSDictionary *)body error:(NSError *)error metadata:(YUNRequestMetadata *)metadata canNotifyDelegate:(BOOL)canNotifyDelegate
{
    void (^finishAndInvokeCompleteHandler)(void) = ^{
        NSDictionary *debugDict = [body objectForKey:@"__debug__"];
        if ([debugDict isKindOfClass:[NSDictionary class]]) {
            [self processResultDebugDictionary: debugDict];
        }
        [metadata invokeCompletionHnadlerConnection:self withResults:body error:error];
        
        if (--_expectingResults == 0) {
            if (canNotifyDelegate && [_delegate respondsToSelector:@selector(requestConnectionDidFinishLoading:)]) {
                [_delegate requestConnectionDidFinishLoading:self];
            }
        }
    };
    
    // this is already on the queue since we are currently in the NSURLConnection callback.
    finishAndInvokeCompleteHandler();
}

- (void)processResultDebugDictionary:(NSDictionary *)dict
{
    NSArray *messages = [YUNTypeUtility arrayValue:dict[@"messages"]];
    if (![messages count]) {
        return;
    }
    
    [messages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *messageDict = [YUNTypeUtility dictionaryValue:obj];
        NSString *message = [YUNTypeUtility stringValue:messageDict[@"message"]];
        NSString *type = [YUNTypeUtility stringValue:messageDict[@"type"]];
        NSString *link = [YUNTypeUtility stringValue:messageDict[@"link"]];
        if (!message || !type) {
            return ;
        }
        
        NSString *loggingBehavior = YUNLoggingBehaviorGraphAPIDebugInfo;
        if ([type isEqualToString:@"warning"]) {
            loggingBehavior = YUNLoggingBehaviorGraphAPIDebugWarning;
        }
        if (link) {
            message = [message stringByAppendingFormat:@" Link: %@", link];
        }
        
        [YUNLogger singleShotLogEntry:loggingBehavior logEntry:message];
    }];
}

- (NSError *)errorFromResult:(id)result request:(YUNRequest *)request
{
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *errorDictionary = [YUNTypeUtility dictionaryValue:result[@"data"]][@"error"];
        
        if (errorDictionary) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"code"] forKey:YUNRequestErrorGraphErrorCode];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"error_subcode"] forKey:YUNRequestErrorGraphErrorSubcode];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"error_msg"] forKey:YUNErrorDeveloperMessageKey];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"error_reason"] forKey:YUNErrorDeveloperMessageKey];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"message"] forKey:YUNErrorDeveloperMessageKey];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"error_user_title"] forKey:YUNErrorLocalizedTitleKey];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"error_user_msg"] forKey:YUNErrorLocalizedDescriptionKey];
            [YUNInternalUtility dictionary:userInfo setObject:errorDictionary[@"error_user_msg"] forKey:NSLocalizedDescriptionKey];
            [YUNInternalUtility dictionary:userInfo setObject:result[@"code"] forKey:YUNRequestErrorHTTPStatusCodeKey];
            [YUNInternalUtility dictionary:userInfo setObject:result forKey:YUNRequestErrorParsedJSONResponseKey];
            
            YUNErrorRecoveryConfiguration *recoveryConfiguration = [g_errorConfiguration recoveryConfigurationForCode:[userInfo[YUNRequestErrorGraphErrorCode] stringValue] subcode:[userInfo[YUNRequestErrorGraphErrorSubcode] stringValue] request:request];
            if ([errorDictionary[@"is_transient"] boolValue]) {
                userInfo[YUNRequestErrorCategoryKey] = @(YUNRequestErrorCategoryTransient);
            } else {
                [YUNInternalUtility dictionary:userInfo setObject:@(recoveryConfiguration.errorCategory) forKey:YUNRequestErrorCategoryKey];
            }
            [YUNInternalUtility dictionary:userInfo setObject:recoveryConfiguration.localizedRecoveryDescription forKey:NSLocalizedRecoverySuggestionErrorKey];
            [YUNInternalUtility dictionary:userInfo setObject:recoveryConfiguration.localizedRecoveryOptionDescriptions forKey:NSLocalizedRecoveryOptionsErrorKey];
            YUNErrorRecoveryAttempter *attempter = [YUNErrorRecoveryAttempter recoveryAttempterFromConfiguration:recoveryConfiguration];
            [YUNInternalUtility dictionary:userInfo setObject:attempter forKey:NSRecoveryAttempterErrorKey];
            
            return [YUNError errorWithCode:YUNRequestAPIErrorCode
                                  userInfo:userInfo
                                   message:nil
                           underlyingError:nil];
        }
    }
    
    return nil;
}

- (NSError *)errorWithCode:(YUNErrorCode)code
                statusCode:(NSInteger)statusCode
        parsedJSONResponse:(id)response
                innerError:(NSError *)innerError
                   message:(NSString *)message {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    userInfo[YUNRequestErrorHTTPStatusCodeKey] = @(statusCode);
    
    if (response) {
        userInfo[YUNRequestErrorParsedJSONResponseKey] = response;
    }
    
    if (innerError) {
        userInfo[YUNRequestErrorParsedJSONResponseKey] = innerError;
    }
    
    if (message) {
        userInfo[YUNErrorDeveloperMessageKey] = message;
    }
    
    NSError *error = [[NSError alloc] initWithDomain:YUNErrorDomain
                                                code:code
                                            userInfo:userInfo];
    
    return error;
}

#pragma mark - Private methods (miscellaneous)

- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(YUNLogger *)bodyLogger
     attatchLogger:(YUNLogger *)attachmentLogger
{
    if (_logger.isActive) {
        [_logger appendFormat:@"Request <#%lu>:\n", (unsigned long)_logger.loggerSerialNumber];
        [_logger appendKey:@"URL" value:[[request URL] absoluteString]];
        [_logger appendKey:@"Method" value:[request HTTPMethod]];
        [_logger appendKey:@"UserAgent" value:[request valueForHTTPHeaderField:@"User-Agent"]];
        [_logger appendKey:@"MIME" value:[request valueForHTTPHeaderField:@"Content-Type"]];
        
        if (bodyLength != 0) {
            [_logger appendKey:@"Body Size" value:[NSString stringWithFormat:@"%lu kB", (unsigned long)bodyLength / 1024]];
        }
        
        if (bodyLogger != nil) {
            [_logger appendKey:@"Body (w/o attachments)" value:bodyLogger.contents];
        }
        
        if (attachmentLogger != nil) {
            [_logger appendKey:@"Attachments" value:attachmentLogger.contents];
        }
        
        [_logger appendString:@"\n"];
        
        [_logger emitToNSLog];
    }
}

- (NSString *)accessTokenWithRequest:(YUNRequest *)request
{
    NSString *token = request.tokenString ?: request.parameters[kAccessTokenKey];
    if (!token && !(request.flags & YUNRequestFlagSkipClientToken && [YUNSettings clientToken].length > 0)) {
        return [NSString stringWithFormat:@"%@|%@", [YUNSettings appID], [YUNSettings clientToken]];
    }
    return token;
}

- (void)registerTokenToOmitFromLog:(NSString *)token
{
    if (![[YUNSettings loggingBehavior] containsObject:YUNLoggingBehaviorAccessTokens]) {
        [YUNLogger registerStringToReplace:token replaceWith:@"ACCESS_TOKEN_REMOVED"];
    }
}

+ (NSString *)userAgent
{
    static NSString *agent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        agent = [NSString stringWithFormat:@"%@", kUserAgentBase];
    });
    
    if ([YUNSettings userAgentSuffix]) {
        return [NSString stringWithFormat:@"%@/%@", agent, [YUNSettings userAgentSuffix]];
    }
    return agent;
}

- (void)setConnection:(YUNURLConnection *)connection
{
    if (_connection != connection) {
        _connection.delegate = nil;
        _connection = connection;
    }
}

#pragma mark - YUNURLConnectionDelegate

- (void)URLConnection:(YUNURLConnection *)connection
      didSendBodyData:(NSInteger)bytesWritten
    totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    id<YUNRequestConnectionDelegate> delegate = [self delegate];
    
    if ([delegate respondsToSelector:@selector(requestConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [delegate requestConnection:self
                    didSendBodyData:bytesWritten
                  totalBytesWritten:totalBytesWritten
          totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

#pragma mark - Debugging helpers

- (NSString *)description
{
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, %lu request(s): (\n",
                               NSStringFromClass([self class]),
                               self,
                               (unsigned long)self.requests.count];
    BOOL comma = NO;
    for (YUNRequestMetadata *metadata in self.requests) {
        YUNRequest *request = metadata.request;
        if (comma) {
            [result appendString:@",\n"];
        }
        [result appendString:[request description]];
        comma = YES;
    }
    [result appendString:@"\n)>"];
    return result;
}



@end
