#import "ModelController.h"
#import "NSFileManager+Helpers.h"

@implementation ModelController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (id)initWithSampleData:(BOOL)useSampleData useZumeroStore:(BOOL)useZumeroStore
{
    self = [super init];
    if (self) {
        self.useZumeroStore = useZumeroStore;
        
        // Initialize the Core Data stack
        if (self.managedObjectContext) {
            
            // Initialize the data if necessary
            if (useSampleData) {
                [self initializeData];
            }
            
            // Update the data if necessary
            [self updateData];
        }
    }
    return self;
}

- (void)initializeData
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    Project *project1 = [Project insertInManagedObjectContext:context];
    [self.managedObjectContext assignObject:project1 toPersistentStore:self.store];
    project1.name = @"Project 1";

    Project *project2 = [Project insertInManagedObjectContext:context];
    [self.managedObjectContext assignObject:project2 toPersistentStore:self.store];
    project2.name = @"Project 2";

    Task *task1 = [Task insertInManagedObjectContext:context];
    task1.name = @"Task 1";
    task1.project = project1;
    
    Manager *manager = [Manager insertInManagedObjectContext:context];
    manager.name = @"John Doe";
    manager.title = @"Middle Manager";
    task1.manager = manager;

    Assistant *assistant1 = [Assistant insertInManagedObjectContext:context];
    assistant1.name = @"Assistant 1";
    assistant1.hourlyRate = [[NSDecimalNumber alloc] initWithString:@"10"];
    [task1 addAssistantsObject:assistant1];
    
    Assistant *assistant2 = [Assistant insertInManagedObjectContext:context];
    assistant2.name = @"Assistant 2";
    assistant2.hourlyRate = [[NSDecimalNumber alloc] initWithString:@"20"];
    [task1 addAssistantsObject:assistant2];
    
    [context saveWithoutSyncing];
}

- (void)updateData
{
    
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption: @(YES)
                              };
    
    NSError *error = nil;
    if (self.useZumeroStore) {
        self.store = [_persistentStoreCoordinator addPersistentStoreWithType:[ZumeroExampleIncrementalStore type]
                                                          configuration:nil
                                                                    URL:nil
                                                                options:options
                                                                  error:&error];
    } else {
        NSURL *storeURL = [[NSFileManager applicationDocumentsDirectory] URLByAppendingPathComponent:@"ZumeroExample.sqlite"];
        self.store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                          configuration:nil
                                                                    URL:storeURL
                                                                options:options
                                                                  error:&error];
    }
    if (! self.store) {
        /*
         Replace this implementation with code to handle the error appropriately.

         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.


         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]

         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}

         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.

         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

@end
