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

OSStatus yundfl_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    _yundfl_Security_get_f(SecItemUpdate);
    return f(query, attributesToUpdate);
}

OSStatus yundfl_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    _yundfl_Security_get_f(SecItemAdd);
    return f(attributes, result);
}

OSStatus yundfl_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    _yundfl_Security_get_f(SecItemCopyMatching);
    return f(query, result);
}

OSStatus yundfl_SecItemDelete(CFDictionaryRef query) {
    _yundfl_Security_get_f(SecItemDelete);
    return f(query);
}

#pragma mark - sqlite3 APIs

// sqlite3 is a dynamic library (not a framework) so its path is constructed differently
// than the way employed by the framework macros.
static void yundfl_load_sqlite3_once(void *context)
{
    *(void **)context = yundfl_load_libarray_once([g_sqlitePath fileSystemRepresentation]);
}
_yundfl_handle_get_impl_(sqlite3);

#define _yundfl_sqlite3_get_f(SYMBOL) _yundfl_symbol_get_f(sqlite3, SYMBOL)

typedef SQLITE_API const char *(*sqlite3_errmsg_type)(sqlite3 *);
typedef SQLITE_API int (*sqlite3_prepare_v2_type)(sqlite3 *, const char *, int, sqlite3_stmt **, const char **);
typedef SQLITE_API int (*sqlite3_reset_type)(sqlite3_stmt *);
typedef SQLITE_API int (*sqlite3_finalize_type)(sqlite3_stmt *);
typedef SQLITE_API int (*sqlite3_open_v2_type)(const char *, sqlite3 **, int, const char *);
typedef SQLITE_API int (*sqlite3_exec_type)(sqlite3 *, const char *, int (*)(void *, int, char **, char **), void *, char **);
typedef SQLITE_API int (*sqlite3_close_type)(sqlite3 *);
typedef SQLITE_API int (*sqlite3_bind_double_type)(sqlite3_stmt *, int, double);
typedef SQLITE_API int (*sqlite3_bind_int_type)(sqlite3_stmt *, int, int);
typedef SQLITE_API int (*sqlite3_bind_text_type)(sqlite3_stmt *, int, const char *, int, void(*)(void *));
typedef SQLITE_API int (*sqlite3_step_type)(sqlite3_stmt *);
typedef SQLITE_API double (*sqlite3_column_double_type)(sqlite3_stmt *, int);
typedef SQLITE_API int (*sqlite3_column_int_type)(sqlite3_stmt *, int);
typedef SQLITE_API const unsigned char *(*sqlite3_column_text_type)(sqlite3_stmt *, int);

SQLITE_API const char *yundfl_sqlite3_errmsg(sqlite3 *db)
{
    _yundfl_sqlite3_get_f(sqlite3_errmsg);
    return f(db);
}

SQLITE_API int yundfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail)
{
    _yundfl_sqlite3_get_f(sqlite3_prepare_v2);
    return f(db, zSql, nByte, ppStmt, pzTail);
}

SQLITE_API int yundfl_sqlite3_reset(sqlite3_stmt *pStmt)
{
    _yundfl_sqlite3_get_f(sqlite3_reset);
    return f(pStmt);
}

SQLITE_API int yundfl_sqlite3_finalize(sqlite3_stmt *pStmt)
{
    _yundfl_sqlite3_get_f(sqlite3_finalize);
    return f(pStmt);
}

SQLITE_API int yundfl_sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs)
{
    _yundfl_sqlite3_get_f(sqlite3_open_v2);
    return f(filename, ppDb, flags, zVfs);
}

SQLITE_API int yundfl_sqlite3_exec(sqlite3 *db, const char *sql, int (*callback)(void *, int, char **, char **), void *arg, char **errmsg)
{
    _yundfl_sqlite3_get_f(sqlite3_exec);
    return f(db, sql, callback, arg, errmsg);
}

SQLITE_API int yundfl_sqlite3_close(sqlite3 *db)
{
    _yundfl_sqlite3_get_f(sqlite3_close);
    return f(db);
}

SQLITE_API int yundfl_sqlite3_bind_double(sqlite3_stmt *stmt, int index , double value)
{
    _yundfl_sqlite3_get_f(sqlite3_bind_double);
    return f(stmt, index, value);
}

SQLITE_API int yundfl_sqlite3_bind_int(sqlite3_stmt *stmt, int index, int value)
{
    _yundfl_sqlite3_get_f(sqlite3_bind_int);
    return f(stmt, index, value);
}

SQLITE_API int yundfl_sqlite3_bind_text(sqlite3_stmt *stmt, int index, const char *value, int n, void(*callback)(void *))
{
    _yundfl_sqlite3_get_f(sqlite3_bind_text);
    return f(stmt, index, value, n, callback);
}

SQLITE_API int yundfl_sqlite3_step(sqlite3_stmt *stmt)
{
    _yundfl_sqlite3_get_f(sqlite3_step);
    return f(stmt);
}

SQLITE_API double yundfl_sqlite3_column_double(sqlite3_stmt *stmt, int iCol)
{
    _yundfl_sqlite3_get_f(sqlite3_column_double);
    return f(stmt, iCol);
}

SQLITE_API int yundfl_sqlite3_column_int(sqlite3_stmt *stmt, int iCol)
{
    _yundfl_sqlite3_get_f(sqlite3_column_int);
    return f(stmt, iCol);
}

SQLITE_API const unsigned char *yundfl_sqlite3_column_text(sqlite3_stmt *stmt, int iCol)
{
    _yundfl_sqlite3_get_f(sqlite3_column_text);
    return f(stmt, iCol);
}

#pragma mark - Social Constants

_yundfl_load_framework_once_impl_(Social)
_yundfl_handle_get_impl_(Social)

#define _yundfl_Social_get_and_return_constant(SYMBOL) _yundfl_get_and_return_NSString(Social, SYMBOL)

NSString *yundfl_SLServiceTypeFacebook(void)
{
    _yundfl_Social_get_and_return_constant(SLServiceTypeFacebook);
}

#pragma mark - Social Classes

#define _yundfl_Social_get_c(SYMBOL) _yundfl_symbol_get_c(Social, SYMBOL)

Class yundfl_SLComposeViewControllerClass(void)
{
    _yundfl_Social_get_c(SLComposeViewController);
    return c;
}

#pragma mark - QuartzCore Classes

_yundfl_load_framework_once_impl_(QuartzCore)
_yundfl_handle_get_impl_(QuartzCore)

#define _yundfl_QuartzCore_get_c(SYMBOL) _yundfl_symbol_get_c(QuartzCore, SYMBOL);

Class yundfl_CATransactionClass(void)
{
    _yundfl_QuartzCore_get_c(CATransaction);
    return c;
}

#pragma mark - QuartzCore APIs

#define _yundfl_QuartzCore_get_f(SYMBOL) _yundfl_symbol_get_f(QuartzCore, SYMBOL)

typedef CATransform3D (*CATransform3DMakeScale_type)(CGFloat, CGFloat, CGFloat);
typedef CATransform3D (*CATransform3DMakeTranslation_type)(CGFloat, CGFloat, CGFloat);
typedef CATransform3D (*CATransform3DConcat_type)(CATransform3D, CATransform3D);

const CATransform3D yundfl_CATransform3DIdentity = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};

CATransform3D yundfl_CATransform3DMakeScale(CGFloat sx, CGFloat sy, CGFloat sz)
{
    _yundfl_QuartzCore_get_f(CATransform3DMakeScale);
    return f(sx, sy, sz);
}

CATransform3D yundfl_CATransform3DMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz)
{
    _yundfl_QuartzCore_get_f(CATransform3DMakeTranslation);
    return f(tx, ty, tz);
}

CATransform3D yundfl_CATransform3DConcat(CATransform3D a, CATransform3D b)
{
    _yundfl_QuartzCore_get_f(CATransform3DConcat);
    return f(a, b);
}

#pragma mark - AudioToolbox APIs

_yundfl_load_framework_once_impl_(AudioToolbox)
_yundfl_handle_get_impl_(AudioToolbox)

#define _yundfl_AudioToolbox_get_f(SYMBOL) _yundfl_symbol_get_f(AudioToolbox, SYMBOL)

typedef OSStatus (*AudioServicesCreateSystemSoundID_type)(CFURLRef, SystemSoundID *);
typedef OSStatus (*AudioServicesDisposeSystemSoundID_type)(SystemSoundID);
typedef void (*AudioServicesPlaySystemSound_type)(SystemSoundID);

OSStatus yundfl_AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID)
{
    _yundfl_AudioToolbox_get_f(AudioServicesCreateSystemSoundID);
    return f(inFileURL, outSystemSoundID);
}

OSStatus yundfl_AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID)
{
    _yundfl_AudioToolbox_get_f(AudioServicesDisposeSystemSoundID);
    return f(inSystemSoundID);
}

void yundfl_AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID)
{
    _yundfl_AudioToolbox_get_f(AudioServicesPlaySystemSound);
    return f(inSystemSoundID);
}

#pragma mark - Ad Support Classes

_yundfl_load_framework_once_impl_(AdSupport)
_yundfl_handle_get_impl_(AdSupport)

#define _yundfl_AdSupport_get_c(SYMBOL) _yundfl_symbol_get_c(AdSupport, SYMBOL);

Class yundfl_ASIdentifierManagerClass(void)
{
    _yundfl_AdSupport_get_c(ASIdentifierManager);
    return c;
}

#pragma mark - Safari Services
_yundfl_load_framework_once_impl_(SafariServices)
_yundfl_handle_get_impl_(SafariServices)

#define _yundfl_SafariServices_get_c(SYMBOL) _yundfl_symbol_get_c(SafariServices, SYMBOL);

Class yundfl_SFSafariViewControllerClass(void)
{
    _yundfl_SafariServices_get_c(SFSafariViewController);
    return c;
}

#pragma mark - Accounts Constants

_yundfl_load_framework_once_impl_(Accounts)
_yundfl_handle_get_impl_(Accounts)

#define _yundfl_Accounts_get_and_return_NSString(SYMBOL) _yundfl_get_and_return_NSString(Accounts, SYMBOL)

NSString *yundfl_ACFacebookAppIdKey(void)
{
    _yundfl_Accounts_get_and_return_NSString(ACFacebookAppIdKey);
}

NSString *yundfl_ACFacebookAudienceEveryone(void)
{
    _yundfl_Accounts_get_and_return_NSString(ACFacebookAudienceEveryone);
}

NSString *yundfl_ACFacebookAudienceFriends(void)
{
    _yundfl_Accounts_get_and_return_NSString(ACFacebookAudienceFriends);
}

NSString *yundfl_ACFacebookAudienceKey(void)
{
    _yundfl_Accounts_get_and_return_NSString(ACFacebookAudienceKey);
}

NSString *yundfl_ACFacebookAudienceOnlyMe(void)
{
    _yundfl_Accounts_get_and_return_NSString(ACFacebookAudienceOnlyMe);
}

NSString *yundfl_ACFacebookPermissionsKey(void)
{
    _yundfl_Accounts_get_and_return_NSString(ACFacebookPermissionsKey);
}

#pragma mark - Accounts Classes

#define _yundfl_Accounts_get_c(SYMBOL) _yundfl_symbol_get_c(Accounts, SYMBOL);

Class yundfl_ACAccountStoreClass(void)
{
    _yundfl_Accounts_get_c(ACAccountStore);
    return c;
}

#pragma mark - StoreKit Classes

_yundfl_load_framework_once_impl_(StoreKit)
_yundfl_handle_get_impl_(StoreKit)

#define _yundfl_StoreKit_get_c(SYMBOL) _yundfl_symbol_get_c(StoreKit, SYMBOL);

Class yundfl_SKPaymentQueueClass(void)
{
    _yundfl_StoreKit_get_c(SKPaymentQueue);
    return c;
}

Class yundfl_SKProductsRequestClass(void)
{
    _yundfl_StoreKit_get_c(SKProductsRequest);
    return c;
}

#pragma mark - AssetsLibrary Classes

_yundfl_load_framework_once_impl_(AssetsLibrary)
_yundfl_handle_get_impl_(AssetsLibrary)

#define _yundfl_AssetsLibrary_get_c(SYMBOL) _yundfl_symbol_get_c(AssetsLibrary, SYMBOL);

Class yundfl_ALAssetsLibraryClass(void)
{
    _yundfl_AssetsLibrary_get_c(ALAssetsLibrary);
    return c;
}

#pragma mark - CoreTelephony Classes

_yundfl_load_framework_once_impl_(CoreTelephony)
_yundfl_handle_get_impl_(CoreTelephony)

#define _yundfl_CoreTelephonyLibrary_get_c(SYMBOL) _yundfl_symbol_get_c(CoreTelephony, SYMBOL);

Class yundfl_CTTelephonyNetworkInfoClass(void)
{
    _yundfl_CoreTelephonyLibrary_get_c(CTTelephonyNetworkInfo);
    return c;
}
