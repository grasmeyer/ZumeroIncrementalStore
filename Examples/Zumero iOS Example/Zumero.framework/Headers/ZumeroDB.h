//
//  ZumeroDB.h
//  zumero-ios
//
//  Created by Paul Roub on 1/3/13.
//  Copyright (c) 2013 SourceGear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZumeroDBDelegate.h"
#include "sqlite3.h"

@interface ZumeroDB : NSObject

@property (nonatomic, retain) id<ZumeroDBDelegate> delegate;
@property (nonatomic) BOOL syncBGThread;

- (id) initWithName: (NSString *) dbname folder:(NSString *)folder host:(NSString *)host;
- (BOOL) attachDatabase: (ZumeroDB **)db dbname:(NSString *) dbname folder:(NSString *)folder attachas:(NSString *)attachas host:(NSString *)host err:(NSError **)err;

- (BOOL) createDB:(NSError **)error;

- (void) setRemoteName:(NSString *)rname;

- (BOOL) createInternalUserTable:(NSError **)error;
- (BOOL) addInternalUser:(NSString *)name password:(NSString *)password error:(NSError **)error;

- (BOOL) addRowRule:(NSString *)table situation:(NSString *)situation action:(NSString *)action error:(NSError **)error;
- (BOOL) addColumnRule:(NSString *)table column:(NSString *)column action:(NSString *)action error:(NSError **)error;

- (BOOL) createACLTable:(NSError **)error;
- (BOOL) addACL:(NSDictionary *)scheme who:(NSString *)who table:(NSString *)table op:(NSString *)op result:(NSString *)result error:(NSError **)error;

- (BOOL) addInternalUserRemoteAnonymous:(NSString *)name password:(NSString *)password error:(NSError **)error;

- (BOOL) sync:(NSDictionary *)scheme user:(NSString *)user password:(NSString *)password error:(NSError **)perr;

- (BOOL) beginTX:(NSError **)err;
- (BOOL) commitTX:(NSError **)err;
- (BOOL) abortTX:(NSError **)err;

- (BOOL) defineTable:(NSString *)table fields:(NSDictionary *)fields error:(NSError **)err;
- (BOOL) tableExists:(NSString *)table;

- (BOOL) insertRecord:(NSString *)table values:(NSDictionary *)values inserted:(NSMutableDictionary *)inserted error:(NSError **)err;
- (BOOL) update:(NSString *)table criteria:(NSDictionary *)criteria values:(NSDictionary *)values error:(NSError **)err;

- (BOOL) recordHistory:(NSString *)table criteria:(NSDictionary *)criteria history:(NSArray **)history error:(NSError **)err;

- (BOOL) exists;

- (BOOL) select:(NSString *)table criteria:(NSDictionary *)criteria columns:(NSArray *)columns orderby:(NSString *)orderby rows:(NSArray **)prows error:(NSError **)error;
- (BOOL) selectSql:(NSString *)sql values:(NSArray *)values rows:(NSArray **)rows error:(NSError **)error;

- (BOOL) execSql:(NSString *)sql values:(NSArray *)values error:(NSError **)error;

- (BOOL) delete:(NSString *)table criteria:(NSDictionary *)criteria error:(NSError **)err;

#if defined (ZUMERO_AES)
- (BOOL) aes_encrypt:(const NSData *)plainText password:(const NSString *)pwd rounds:(NSUInteger)rounds encrypted:(NSData **)encrypted error:(NSError **)err;
- (BOOL) aes_decrypt:(const NSData *)encrypted password:(const NSString *)pwd decrypted:(NSData **)decrypted error:(NSError **)err;
#endif

- (NSString *)dbpath;

- (NSUInteger) lastError;

- (BOOL)open:(NSError **)err;
- (BOOL)isOpen;
- (BOOL)close;
- (BOOL)detach:(NSError **)err;

- (sqlite3 *)db;

//+ (NSString *)genUUID;

@end
