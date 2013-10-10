@interface NSManagedObjectContext (Helpers)

- (BOOL)saveWithoutSyncing;
- (BOOL)saveAndSync;

@end
