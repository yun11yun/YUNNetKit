//
//  YUNDynamicFrameworkLoader.h
//  YUNNetKit
//
//  Created by bit_tea on 16/5/8.
//  Copyright © 2016年 bit_tea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#import "YUNMacros.h"

/*
 @class YUNDynamicFrameworkLoader
 
 @abstract 
 This class provides a way to load constants and methods from Apple Frameworks in a dynamic 
 fashion. It allows the SDK to be just dragged into a project without having to specity additional
 frameworks to link against. It is an internal class and not to be used by 3rd party developers.
 
 As new types are needed, they should be added and strongly typed.
 */

@interface YUNDynamicFrameworkLoader : NSObject

#pragma mark - Security Constants

/*
 @abstract
 Load the kSecRandomDefault value from the Security Framework
 
 @return The kSecRandomDefault value or nil.
 */
+ (SecRandomRef)loadkSecRandomDefault;

/*
 @abstract
 Load the kSecAttrAccessible value from the Security Framework
 
 @return The kSecAttrAccessible value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccessible;

/*
 @abstract 
 Load the kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly value from the Security Framework
 
 @return The kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;

/*
 @abstract
 Load the kSecAttrService value from the Security Framework
 
 @return The kSecAttrService value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccount;

/*
 @abstract
 Load the kSecAttrService value from the Security Framework
 
 @return The kSecAttrService value or nil.
 */
+ (CFTypeRef)loadkSecAttrService;

/*
 @abstract 
 Load the kSecAttrGeneric value from the Security Framework
 
 @return The kSecAttrGeneric value or nil.
 */
+ (CFTypeRef)loadkSecAttrGeneric;

/*!
 @abstract
 Load the kSecValueData value from the Security Framework
 
 @return The kSecValueData value or nil.
 */
+ (CFTypeRef)loadkSecValueData;

/*!
 @abstract
 Load the kSecClassGenericPassword value from the Security Framework
 
 @return The kSecClassGenericPassword value or nil.
 */
+ (CFTypeRef)loadkSecClassGenericPassword;

/*!
 @abstract
 Load the kSecAttrAccessGroup value from the Security Framework
 
 @return The kSecAttrAccessGroup value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccessGroup;

/*!
 @abstract
 Load the kSecMatchLimitOne value from the Security Framework
 
 @return The kSecMatchLimitOne value or nil.
 */
+ (CFTypeRef)loadkSecMatchLimitOne;

/*!
 @abstract
 Load the kSecMatchLimit value from the Security Framework
 
 @return The kSecMatchLimit value or nil.
 */
+ (CFTypeRef)loadkSecMatchLimit;

/*!
 @abstract
 Load the kSecReturnData value from the Security Framework
 
 @return The kSecReturnData value or nil.
 */
+ (CFTypeRef)loadkSecReturnData;

/*!
 @abstract
 Load the kSecClass value from the Security Framework
 
 @return The kSecClass value or nil.
 */
+ (CFTypeRef)loadkSecClass;

@end

#pragma mark - Security APIs

// These are local wrappers around the corresponding methods in Security/SecRandom.h
extern int yundfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes);

// These are local wrappers around Keychain API
extern OSStatus yundfl_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
extern OSStatus yundfl_SecItemAdd(CFDictionaryRef attributes,CFTypeRef *result);
extern OSStatus yundfl_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);
extern OSStatus yundfl_SecItemDelete(CFDictionaryRef query);

#pragma mark - sqlite3 APIs

// These are local wrappers around the corresponding sqlite3 method from / usr / include / sqlite3.h
extern SQLITE_API const char *yundfl_sqlite3_errmsg(sqlite3 *db);
extern SQLITE_API int yundfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
extern SQLITE_API int yundfl_sqlite3_reset(sqlite3_stmt *pStmt);
extern SQLITE_API int yundfl_sqlite3_finalize(sqlite3_stmt *pStmt);
extern SQLITE_API int yundfl_sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs);
extern SQLITE_API int yundfl_sqlite3_exec(sqlite3 *db, const char *sql, int (*callbacl)(void *, int, char **, char **), void *arg, char **errmsg);
extern SQLITE_API int yundfl_sqlite3_close(sqlite3 *db);
extern SQLITE_API int yundfl_sqlite3_bind_double(sqlite3_stmt *stmt, int index, double value);
extern SQLITE_API int yundfl_sqlite3_bind_int(sqlite3_stmt *stmt, int index, int value);
extern SQLITE_API int yundfl_sqlite3_bind_text(sqlite3_stmt *stmt, int index, const char *value, int n, void(*callback)(void *));
extern SQLITE_API int yundfl_sqlite3_step(sqlite3_stmt *stmt);
extern SQLITE_API double yundfl_sqlite3_column_double(sqlite3_stmt *stmt, int iCol);
extern SQLITE_API int yundfl_sqlite3_column_int(sqlite3_stmt *stmt, int iCol);
extern SQLITE_API const unsigned char * yundfl_sqlite3_column_text(sqlite3_stmt *stmt, int iCol);

#pragma mark - Social Constants 

extern NSString *yundfl_SLServiceTypeFacebook(void);

#pragma mark - Social Classes

extern Class yundfl_SLComposeViewControllerClass(void);

#pragma mark - QuartzCore Classes

extern Class yunfl_CATransactionClass(void);

#pragma mark - QuartzCore APIs

// These are local wrappers around the corresponding transform methods from QuartzCore.framework/CATransform3D.h
extern CATransform3D yundfl_CATransform3DMakeScale (CGFloat sx, CGFloat sy, CGFloat sz);
extern CATransform3D yundfl_CATransform3DMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz);
extern CATransform3D yundfl_CATransform3DConcat (CATransform3D a, CATransform3D b);

extern const CATransform3D yundfl_CATransform3DIdentity;

#pragma mark - AudioToolbox APIs

// These are local wrappers around the corresponding methods in AudioToolbox/AudioToolbox.h
extern OSStatus yundfl_AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID);
extern OSStatus yundfl_AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID);
extern void yundfl_AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID);

#pragma mark - AdSupport Classes

extern Class yundfl_ASIdentifierManagerClass(void);

#pragma mark - SafariServices Classes

extern Class yundfl_SFSafariViewControllerClass(void);

#pragma mark - Accounts Constants

extern NSString *yundfl_ACFacebookAppIdKey(void);
extern NSString *yundfl_ACFacebookAudienceEveryone(void);
extern NSString *yundfl_ACFacebookAudienceFriends(void);
extern NSString *yundfl_ACFacebookAudienceKey(void);
extern NSString *yundfl_ACFacebookAudienceOnlyMe(void);
extern NSString *yundfl_ACFacebookPermissionsKey(void);


#pragma mark - Accounts Classes

extern Class yundfl_ACAccountStoreClass(void);

#pragma mark - StoreKit classes

extern Class yundfl_SKPaymentQueueClass(void);
extern Class yundfl_SKProductsRequestClass(void);

#pragma mark - AssetsLibrary Classes

extern Class yundfl_AFAssetsLibraryClass(void);

#pragma mark - CoreTelephony Classes

extern Class yundfl_CTTelephonyNetworkInfoClass(void);


