#import "Model.h"
#import "MockIncrementalStore.h"
#import "NSManagedObjectContext+Helpers.h"
#import "NSFileManager+Helpers.h"

@interface MockModelController : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSPersistentStore *store;
@property BOOL useZumeroStore;

- (id)initWithSampleData:(BOOL)useSampleData useZumeroStore:(BOOL)useZumeroStore;

@end
