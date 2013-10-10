#import <CoreData/CoreData.h>
#import <Zumero/Zumero.h>

@interface ZumeroIncrementalStore : NSIncrementalStore <ZumeroDBDelegate>

typedef BOOL (^ZumeroTransactionBlock)();
typedef void (^ZumeroSyncCompletionBlock)(BOOL success, NSError *error);

extern NSString * const ZumeroIncrementalStoreUnimplementedMethodException;

+ (NSString *)type;
+ (NSManagedObjectModel *)model;
+ (NSString *)databaseFilename;
+ (NSString *)databaseRemoteFilename;
+ (NSString *)server;
+ (NSString *)username;
+ (NSString *)password;
+ (NSDictionary *)scheme;
- (BOOL)syncWithCompletionBlock:(ZumeroSyncCompletionBlock)completionBlock;

@end
