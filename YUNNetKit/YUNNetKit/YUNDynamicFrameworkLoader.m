//
//  YUNDynamicFrameworkLoader.m
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import "YUNDynamicFrameworkLoader.h"

#import <dlfcn.h>
#import <Security/Security.h>
#import <StoreKit/StoreKit.h>

#import "YUNLogger.h"
#import "YUNSettings.h"

static NSString *const g_frameworkPathTemplate = @"/System/Library/Framework/%@.framework/%@";
static NSString *const g_sqlitePath = @"/usr/lib/libsqlite3.dylib";

#pragma mark - Library and Sysbol Loading

struct YUNDFLLoadSymbolContext
{
    void *(*library)(void); // function to retrieve the library handle (it's a function instead of void * so it can be staticlly bound)
    const char *name;       // name of the symbol to retrieve
    void **address;         // [out] address of the symbol in the process address space
};

// Retrieves the handle for a library for framework. The paths for each are constructed
// differently so the loading function passed to dispatch_once() calls this.
static void *yundfl_load_libarray_once(const char *path)
{
    void *handle = dlopen(path, RTLD_LAZY);
    if (handle) {
        [YUNLogger singleShotLogEntry:YUNLoggingBehaviorInformational formatString:@"Dynamically loaded library at %s", path];
    } else {
        [YUNLogger singleShotLogEntry:YUNLoggingBehaviorInformational formatString:@"Failed to load library at %s", path];
    }
    return handle;
}

// Constructs the path for system framework with the given name and returns the handle for dlsym
static void *yundfl_load_framework_once(NSString *framework)
{
    NSString *path = [NSString stringWithFormat:g_frameworkPathTemplate,framework, framework];
    return yundfl_load_libarray_once([path fileSystemRepresentation]);
}

// Implements the callback for dispatch_once() that loads the handle for specified framework name
#define _yundfl_load_framework_once_impl_(FRAMEWORK) \
   static void yundfl_load_##FRAMEWORK##_once(void *context) { \
    *(void **)context = yundfl_load_framework_once(@#FRAMEWORK); \
  }

// Implements the framework/library retrieval function for the given name.
// It calls the loading function once and caches the handle in a local static variable
#define _yundfl_handle_get_impl_(LIBRARY) \
  static void *yundfl_handle_get_##LIBRARY(void) { \
    static void *LIBRARY##_handle; \
    static dispatch_once_t LIBRARY##_once; \
    dispatch_once_f(&LIBRARY##_once, &LIBRARY##_handle, &yundfl_load_##LIBRARY##_once); \
    return LIBRARY##_handle;\
  }

// Callback from dispatch_once() to load a specific symbol
static void yundfl_load_symbol_once(void *context)
{
    struct YUNDFLLoadSymbolContext *ctx = context;
    *ctx->address = dlsym(ctx->library(), ctx->name);
}

// The boiderplate code for loading a symbol from a given library once and caching it in a static local
#define _yundfl_symbol_get(LIBRARY, PREFIX, SYMBOL, TYPE, VARIABLE_NAME) \
   static TYPE VARIABLE_NAME; \
   static dispatch_once_t SYMBOL##_once; \
   static struct YUNDFLLoadSymbolContext ctx = { .library = &yundfl_handle_get_##LIBRARY, .name = PREFIX #SYMBOL, .address = (void **)&VARIABLE_NAME }; \
   dispatch_once_f(&SYMBOL##_once, &ctx, &yundfl_load_symbol_once)


#define _yundfl_symbol_get_c(LIBRARY, SYMBOL) _yundfl_symbol_get(LIBRARY, "OBJC_CLASS_$_", SYMBOL, Class, c) // convenience symbol retrieval macro for getting an Objective-C class symbol and storing it in the local static c
#define _yundfl_symbol_get_f(LIBRARY, SYMBOL) _yundfl_symbol_get(LIBRARY, "", SYMBOL, SYMBOL##_type, f)      // convenience symbol retrieval macro for getting a function pointer and storing it in the local static f
#define _yundfl_symbol_get_k(LIBRARY, SYMBOL, TYPE) _yundfl_symbol_get(LIBRARY, "", SYMBOL, TYPE, k)         // convenience symbol retrieval macro for getting a pointer to a named variable and storing it in the local static k

// convenience macro for verifying a pointer to a named variable was successfully loaded and returns the value
#define _yundfl_return_k(FRAMEWORK, SYMBOL) \
   NSCAssert(k != NULL, @"Failed to load constant %@ in the %@ framework", @#SYMBOL, @#FRAMEWORK); \
   return *k

// convenience macro for getting a pointer to a named NSString, verifying it loaded correctly, and returning it
#define _yundfl_get_and_return_NSString(LIBRARY, SYMBOL) \
   _yundfl_symbol_get_k(LIBRARY, SYMBOL, NSString **); \
   NSCAssert([*k isKindOfClass:[NSString class]], @"Loaded symbol %@ is not of type NSString *", @#SYMBOL); \
   _yundfl_return_k(LIBRARY, SYMBOL)

  #pragma mark - Security Framework

_yundfl_load_framework_once_impl_(Security)
_yundfl_handle_get_impl_(Security)

#pragma mark - Security Constants

@implementation YUNDynamicFrameworkLoader

#define _yundfl_Security_get_k(SYMBOL) _yundfl_symbol_get_k(Security, SYMBOL, CFTypeRef *)

#define _yundfl_Security_get_and_return_k(SYMBOL) \
   _yundfl_Security_get_k(SYMBOL); \
   _yundfl_return_k(Security, SYMBOL)

+ (SecRandomRef)loadkSecRandomDefault
{
    _yundfl_symbol_get_k(Security, kSecRandomDefault, SecRandomRef *);
    _yundfl_return_k(Security, kSecRandomDefault);
}

+ (CFTypeRef)loadkSecAttrAccessible
{
    _yundfl_Security_get_and_return_k(kSecAttrAccessible);
}

+ (CFTypeRef)loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
{
    _yundfl_Security_get_and_return_k(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly);
}

+ (CFTypeRef)loadkSecAttrAccount
{
    _yundfl_Security_get_and_return_k(kSecAttrAccount);
}

+ (CFTypeRef)loadkSecAttrService
{
    _yundfl_Security_get_and_return_k(kSecAttrService);
}

+ (CFTypeRef)loadkSecAttrGeneric
{
    _yundfl_Security_get_and_return_k(kSecAttrGeneric);
}

+ (CFTypeRef)loadkSecValueData
{
    _yundfl_Security_get_and_return_k(kSecValueData);
}

+ (CFTypeRef)loadkSecClassGenericPassword
{
    _yundfl_Security_get_and_return_k(kSecClassGenericPassword);
}

+ (CFTypeRef)loadkSecAttrAccessGroup
{
    _yundfl_Security_get_and_return_k(kSecAttrAccessGroup);
}

+ (CFTypeRef)loadkSecMatchLimitOne
{
    _yundfl_Security_get_and_return_k(kSecMatchLimitOne);
}

+ (CFTypeRef)loadkSecMatchLimit
{
    _yundfl_Security_get_and_return_k(kSecMatchLimit);
}

+ (CFTypeRef)loadkSecReturnData
{
    _yundfl_Security_get_and_return_k(kSecReturnData);
}

+ (CFTypeRef)loadkSecClass
{
    _yundfl_Security_get_and_return_k(kSecClass);
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    YUN_NO_DESIGNATED_INITIALIZER();
    return nil;
}

@end

#pragma mark - Security APIs

#define _yundfl_Security_get_f(SYMBOL) _yundfl_symbol_get_f(Security, SYMBOL)

typedef int (*SecRandomCopyBytes_type)(SecRandomRef, size_t, uint8_t *);
typedef OSStatus (*SecItemUpdate_type)(CFDictionaryRef, CFDictionaryRef);
typedef OSStatus (*SecItemAdd_type)(CFDictionaryRef, CFTypeRef);
typedef OSStatus (*SecItemCopyMatching_type)(CFDictionaryRef, CFTypeRef);
typedef OSStatus (*SecItemDelete_type)(CFDictionaryRef);

int yundfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes)
{
    _yundfl_Security_get_f(SecRandomCopyBytes);
    return f(rnd, count, bytes);
}


