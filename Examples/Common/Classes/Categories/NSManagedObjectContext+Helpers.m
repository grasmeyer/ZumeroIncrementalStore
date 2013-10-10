#import "NSManagedObjectContext+Helpers.h"
#import "AppDelegate.h"

@implementation NSManagedObjectContext (Helpers)

- (BOOL)saveWithoutSyncing
{
    NSError *error = nil;
    if ([self hasChanges]) {
        if ([self save:&error]) {
            return YES;
        } else {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return NO;
        }
    }
    return YES;
}

- (BOOL)saveAndSync
{
    NSError *error = nil;
    if ([self hasChanges]) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        // Reset the idle timer so that the managedObjectContext has a chance to save before syncing
        [appDelegate resetIdleTimer:5];
        if ([self save:&error]) {
            // Sync after the managedObjectContext successfully saves the data
            [appDelegate syncAfterDelay:1];
            return YES;
        } else {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            return NO;
        }
    }
    return YES;
}

@end
