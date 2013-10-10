#import "Model.h"
#import "ZumeroExampleIncrementalStore.h"
#import "NSManagedObjectContext+Helpers.h"

@interface ModelController : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSPersistentStore *store;
@property BOOL useZumeroStore;

- (id)initWithSampleData:(BOOL)useSampleData useZumeroStore:(BOOL)useZumeroStore;

@end
