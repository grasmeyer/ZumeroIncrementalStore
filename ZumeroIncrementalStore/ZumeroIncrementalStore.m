#import "ZumeroIncrementalStore.h"

// This code comes from the following post by Marcus Zarra
// http://www.cimgf.com/2010/05/02/my-current-prefix-pch-file/
#if DEBUG
#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#else
#define DLog(...) do { } while (0)
#ifndef NS_BLOCK_ASSERTIONS
#define NS_BLOCK_ASSERTIONS
#endif
#define ALog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif

#define ZAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while(0)

NSString * const ZumeroIncrementalStoreUnimplementedMethodException = @"com.zumero.incremental-store.exceptions.unimplemented-method";
static NSString * const ZumeroIncrementalStoreMetadataTableName = @"Metadata";
static NSString * const ZumeroIncrementalStoreMetadataColumnName = @"plist";
static NSString * const ZumeroIncrementalStoreTemporaryDatabaseName = @"temporarydatabase";

#pragma mark - NSArray category

@interface NSArray (ZumeroIncrementalStoreAdditions)

/*
 
 Creates an array with the given object repeated for the given number of times.
 
 */
+ (NSArray *)cmdArrayWithObject:(id<NSCopying>)object times:(NSUInteger)times;

/*
 
 Recursively flattens the receiver. Any object that is another array inside
 the receiver has its contents flattened and added as siblings to all
 other objects.
 
 */
- (NSArray *)cmdFlatten;

@end


@implementation NSArray (ZumeroIncrementalStoreAdditions)

+ (NSArray *)cmdArrayWithObject:(id)object times:(NSUInteger)times
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:times];
    for (NSUInteger i = 0; i < times; i++) {
        [array addObject:object];
    }
    return [array copy];
}

- (NSArray *)cmdFlatten
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [array addObjectsFromArray:[obj cmdFlatten]];
        }
        else {
            [array addObject:obj];
        }
    }];
    return array;
}

@end


@interface ZumeroIncrementalStore()

@property (nonatomic) ZumeroDB *database;
@property (nonatomic) ZumeroDB *temporaryDatabase;
@property (nonatomic, strong) ZumeroSyncCompletionBlock syncCompletionBlock;

@end


@implementation ZumeroIncrementalStore

#pragma mark - Class methods

+ (NSString *)type
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +type. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSManagedObjectModel *)model
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +model. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSString *)databaseFilename
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +databaseFilename. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSString *)databaseRemoteFilename
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +databaseRemoteFilename. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSString *)server
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +server. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSString *)username
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +username. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSString *)password
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +password. Must be overridden in a subclass" userInfo:nil]);
}

+ (NSDictionary *)scheme
{
    @throw([NSException exceptionWithName:ZumeroIncrementalStoreUnimplementedMethodException reason:@"Unimplemented method: +scheme. Must be overridden in a subclass" userInfo:nil]);
}

#pragma mark - NSIncrementalStore subclass methods

- (BOOL)loadMetadata:(NSError *__autoreleasing *)error
{
    if (! [self initializeDatabase:self.database]) {
        return NO;
    }
    
    if (! [self.database tableExists:ZumeroIncrementalStoreMetadataTableName]) {
        
        // If the store was just created, initialize the ACL, Schema, and Metadata
        if (! [self initializeACL]) {
            return NO;
        }
        if (! [self initializeSchemaForModel:[[self class] model] database:self.database]) {
            return NO;
        }
        if (! [self initializeMetadata]) {
            return NO;
        }
        
    } else {
        
        // If the store already exists, perform a migration if necessary
        if (! [self migrateDatabase:error]) {
            return NO;
        }
    }
    return YES;
}

- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)objects
                                    error:(NSError *__autoreleasing *)error
{
    DLog(@"");
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (NSManagedObject *object in objects) {
        NSManagedObjectID *objectID = [object objectID];
        if ([objectID isTemporaryID]) {
            NSString *primaryKeyValue = [self insertRecordForEntity:[object entity]];
            objectID = [self newObjectIDForEntity:object.entity referenceObject:primaryKeyValue];
        }
        [objectIDs addObject:objectID];
    }
    return objectIDs;
}

- (id)executeRequest:(NSPersistentStoreRequest *)persistentStoreRequest
         withContext:(NSManagedObjectContext *)context
               error:(NSError *__autoreleasing *)error
{
    DLog(@"");
    if (persistentStoreRequest.requestType == NSFetchRequestType) {
        return [self executeFetchRequest:(NSFetchRequest *)persistentStoreRequest withContext:context error:error];
    } else if (persistentStoreRequest.requestType == NSSaveRequestType) {
        return [self executeSaveChangesRequest:(NSSaveChangesRequest *)persistentStoreRequest withContext:context error:error];
    } else {
        NSString *errorMessage = [NSString stringWithFormat:@"Unsupported NSFetchRequestResultType, %d", persistentStoreRequest.requestType];
        if (error) {
            *error = [NSError errorWithDomain:[self type]
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        }
        return nil;
    }
}

// This method fulfills a fault for an object with a given objectID
- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID
                                         withContext:(NSManagedObjectContext *)context
                                               error:(NSError *__autoreleasing *)error
{
    DLog(@"");
    NSEntityDescription *entity = [objectID entity];
    NSString *tableName = [self tableNameForEntity:entity];
    NSString *primaryKeyName = [self primaryKeyNameForEntity:entity];
    NSString *primaryKeyValue = [self referenceObjectForObjectID:objectID];
    
    NSArray *rows = nil;
    //    DLog(@"%@, %@, %@, %@", [entity name], objectID, primaryKeyName, primaryKeyValue);
    BOOL ok = [self.database select:tableName
                           criteria:@{ primaryKeyName : primaryKeyValue }
                            columns:nil
                            orderby:nil
                               rows:&rows
                              error:error];
    if (ok && [rows count] == 1) {
        NSDictionary *databaseDictionary = [rows firstObject];
        //        DLog(@"databaseDictionary: %@", databaseDictionary);
        NSMutableDictionary *objectDictionary = [NSMutableDictionary dictionary];
        
        // enumerate properties
        NSDictionary *properties = [entity propertiesByName];
        [properties enumerateKeysAndObjectsUsingBlock:^(id objectPropertyName, id objectPropertyDescription, BOOL *stop) {
            if ([objectPropertyDescription isKindOfClass:[NSAttributeDescription class]]) {
                NSString *databaseColumnName = objectPropertyName;
                id databaseColumnValue = [databaseDictionary objectForKey:databaseColumnName];
                if (databaseColumnValue != [NSNull null]) {
                    id objectPropertyValue = databaseColumnValue;
                    [objectDictionary setObject:objectPropertyValue forKey:objectPropertyName];
                }
                
            } else if ([objectPropertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
                
                NSRelationshipDescription *inverse = [objectPropertyDescription inverseRelationship];
                
                // Handle many-to-one and one-to-one
                // One-to-many is handled in the newValueForRelationship method below
                if (![objectPropertyDescription isToMany] || [inverse isToMany]) {
                    NSEntityDescription *target = [(id)objectPropertyDescription destinationEntity];
                    NSString *databaseColumnName = [self foreignKeyNameForRelationship:objectPropertyDescription];
                    id databaseColumnValue = [databaseDictionary objectForKey:databaseColumnName];
                    if (databaseColumnValue != [NSNull null]) {
                        NSManagedObjectID *objectPropertyValue = [self newObjectIDForEntity:target referenceObject:databaseColumnValue];
                        [objectDictionary setObject:objectPropertyValue forKey:objectPropertyName];
                    }
                }
            }
        }];
        //        DLog(@"objectDictionary: %@", objectDictionary);
        NSIncrementalStoreNode *node = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID
                                                                             withValues:objectDictionary
                                                                                version:1];
        return node;
    }
    return nil;
}

- (id)newValueForRelationship:(NSRelationshipDescription *)relationship
              forObjectWithID:(NSManagedObjectID *)objectID
                  withContext:(NSManagedObjectContext *)context
                        error:(NSError *__autoreleasing *)error
{
    DLog(@"");
    //    DLog(@"Entity: %@, relationship: %@, many-to-many: %d", [[relationship entity] name], [relationship name], [[relationship inverseRelationship] isToMany]);
    //    DLog(@"sourceEntity: %@, destinationEntity: %@", [[objectID entity] name], [[relationship destinationEntity] name]);
    
    NSEntityDescription *destinationEntity = [relationship destinationEntity];
    NSArray *objectIDs = nil;
    
    if ([relationship isToMany]) {
        
        NSRelationshipDescription *inverseRelationship = [relationship inverseRelationship];
        if ([inverseRelationship isToMany]) {
            
            // Many-to-many relationships
            NSString *tableName = [self tableNameForRelationship:relationship];
            NSString *relationshipForeignKeyName = [self foreignKeyNameForRelationship:relationship];
            NSString *inverseForeignKeyName = [self foreignKeyNameForRelationship:inverseRelationship];
            NSString *inverseForeignKeyValue = [self referenceObjectForObjectID:objectID];
            //            DLog(@"%@: %@", inverseForeignKeyName, inverseForeignKeyValue);
            NSArray *rows = nil;
            BOOL ok = [self.database select:tableName
                                   criteria:@{ inverseForeignKeyName : inverseForeignKeyValue }
                                    columns:nil
                                    orderby:nil
                                       rows:&rows
                                      error:error];
            if (ok && [rows count] > 0) {
                NSMutableArray *mutableObjectIDs = [NSMutableArray array];
                for (NSDictionary *dictionary in rows) {
                    NSString *relationshipForeignKeyValue = [dictionary objectForKey:relationshipForeignKeyName];
                    [mutableObjectIDs addObject:[self newObjectIDForEntity:destinationEntity referenceObject:relationshipForeignKeyValue]];
                }
                objectIDs = [NSArray arrayWithArray:mutableObjectIDs];
            }
            
        } else {
            
            // One-to-many relationships
            NSString *tableName = [self tableNameForEntity:destinationEntity];
            NSString *foreignKeyName = [self foreignKeyNameForRelationship:inverseRelationship];
            NSString *foreignKeyValue = [self referenceObjectForObjectID:objectID];
            //            DLog(@"%@: %@", foreignKeyName, foreignKeyValue);
            NSArray *rows = nil;
            BOOL ok = [self.database select:tableName
                                   criteria:@{ foreignKeyName : foreignKeyValue }
                                    columns:nil
                                    orderby:nil
                                       rows:&rows
                                      error:error];
            if (ok && [rows count] > 0) {
                NSMutableArray *mutableObjectIDs = [NSMutableArray array];
                NSString *primaryKeyName = [self primaryKeyNameForEntity:destinationEntity];
                for (NSDictionary *dictionary in rows) {
                    NSString *primaryKeyValue = [dictionary objectForKey:primaryKeyName];
                    [mutableObjectIDs addObject:[self newObjectIDForEntity:destinationEntity referenceObject:primaryKeyValue]];
                }
                objectIDs = [NSArray arrayWithArray:mutableObjectIDs];
            }
        }
    }
    return objectIDs;
}

#pragma mark - Database initialization

- (ZumeroDB *)database
{
    if (! _database) {
        _database = [[ZumeroDB alloc] initWithName:[[self class] databaseFilename] folder:nil host:[[self class] server]];
        [_database setRemoteName:[[self class] databaseRemoteFilename]];
        [_database setDelegate:self];
    }
    return _database;
}

- (ZumeroDB *)temporaryDatabase
{
    if (! _temporaryDatabase) {
        // Remove the temporary database in case it already exists
        [[NSFileManager defaultManager] removeItemAtPath:[self temporaryDatabasePath] error:nil];
        
        ZumeroDB *temp = nil;
        NSError *error = nil;
        BOOL ok = [self.database attachDatabase:&temp
                                         dbname:ZumeroIncrementalStoreTemporaryDatabaseName
                                         folder:nil
                                       attachas:ZumeroIncrementalStoreTemporaryDatabaseName
                                           host:nil
                                            err:&error];
        if (ok) {
            _temporaryDatabase = temp;
        }
    }
    return _temporaryDatabase;
}

- (BOOL)initializeDatabase:(ZumeroDB *)database
{
    if (! database) {
        [self reportErrorWithTitle:@"Unable to Initialize Database"
                       description:@"Could not initialize local copy of the database"
                             error:nil];
        exit(-1);
    }
    
    NSError *error = nil;
    if (! [database exists]) {
        if (! [database createDB:&error]) {
            [self reportErrorWithTitle:@"Unable to Create Database"
                           description:@"Could not create local copy of the database"
                                 error:error];
            exit(-1);
        }
    }
    
    BOOL ok = [database isOpen] || [database open:&error];
    if (! ok) {
        [self reportErrorWithTitle:@"Unable to Open Database"
                       description:@"Could not open local copy of the database"
                             error:error];
        exit(-1);
    }
    return ok;
}

- (BOOL)initializeACL
{
    //    if (ok && ! [_db tableExists:@"z_acl"])
    //	{
    //		ok = [_db beginTX:&err] &&
    //		[_db createACLTable:&err] &&
    //		[_db addACL:[ZWConfig scheme]
    //				who:[ZumeroACL who_any_auth]
    //			  table:@""
    //				 op:[ZumeroACL op_all]
    //			 result:[ZumeroACL result_allow]
    //			  error:&err] &&
    //		[_db commitTX:&err];
    //	}
    return YES;
}

- (BOOL)initializeSchemaForModel:(NSManagedObjectModel *)model database:(ZumeroDB *)database
{
    if (! [self createMetadataTableWithDatabase:database]) {
        return NO;
    }
    NSArray *entities = [model entities];
    for (NSEntityDescription *entity in entities) {
        if (! [self createTableForEntity:entity database:database]) {
            return NO;
        }
        if (! [self createJoinTablesForEntity:entity database:database]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)initializeMetadata
{
    [self setMetadata:@{
                        NSStoreUUIDKey : [[self class] identifierForNewStoreAtURL:[self URL]],
                        NSStoreTypeKey : [self type]
                        }];
    return [self saveMetadataToDatabase];
}

- (BOOL)migrateDatabase:(NSError *__autoreleasing *)error
{
    // Check if the store is using the current model
    BOOL success = YES;
    NSDictionary *options = [self options];
    if ([[options objectForKey:NSMigratePersistentStoresAutomaticallyOption] boolValue] &&
        [[options objectForKey:NSInferMappingModelAutomaticallyOption] boolValue]) {
        
        // Get the model from the main bundle which corresponds to the store
        // Other options are allBundles and allFrameworks
        NSArray *bundles = @[[NSBundle mainBundle]];
        NSDictionary *metadata = [self metadataFromStore:error];
        if (! metadata) {
            return NO;
        }
        NSManagedObjectModel *oldModel = [NSManagedObjectModel mergedModelFromBundles:bundles forStoreMetadata:metadata];
        NSManagedObjectModel *newModel = [[self persistentStoreCoordinator] managedObjectModel];
        
        if (! [oldModel isEqual:newModel]) {
        
            // Run migrations if the model used to create the store is different than the current model
            success = [self migrateFromModel:oldModel toModel:newModel error:error];
            if (! success) {
                return NO;
            }
            
            // Update the metadata with the hashes from the new model
            NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
            [mutableMetadata setObject:[newModel entityVersionHashesByName] forKey:NSStoreModelVersionHashesKey];
            [self setMetadata:mutableMetadata];
            [self saveMetadataToDatabase];
            
        } else {
            
            // If we don't need to migrate the data, just set the metadata
            // to the values loaded from the store
            [self setMetadata:metadata];
        }
    }
    return success;
}

#pragma mark - Metadata table

- (BOOL)createMetadataTableWithDatabase:(ZumeroDB *)database
{
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSDictionary *fields = @{ ZumeroIncrementalStoreMetadataColumnName : @{ @"type" : @"blob" } };
        NSError *error = nil;
        BOOL ok = [database defineTable:ZumeroIncrementalStoreMetadataTableName
                                 fields:fields
                                  error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to create %@ table", ZumeroIncrementalStoreMetadataTableName]
                                     error:error];
        }
        return ok;
    };
    
    return [self processTransaction:transaction database:database];
}

- (NSDictionary *)metadataFromStore:(NSError *__autoreleasing *)error
{
    __block NSDictionary *metadata = nil;
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ LIMIT 1", ZumeroIncrementalStoreMetadataColumnName, ZumeroIncrementalStoreMetadataTableName];
        NSArray *rows = nil;
        BOOL ok = [weakSelf.database selectSql:query
                                        values:nil
                                          rows:&rows
                                         error:error];
        if (ok && [rows count] == 1) {
            NSDictionary *databaseDictionary = [rows firstObject];
            NSData *data = [databaseDictionary objectForKey:ZumeroIncrementalStoreMetadataColumnName];
            metadata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        } else {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:@"Unable to select existing metadata"
                                     error:*error];
        }
        return ok;
    };
    
    [self processTransaction:transaction database:self.database];
    
    return metadata;
}

- (BOOL)saveMetadataToDatabase
{
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        
        // First, delete the existing metadata (it may not exist if this is the first run of the app)
        NSString *query = [NSString stringWithFormat:@"DELETE FROM %@", ZumeroIncrementalStoreMetadataTableName];
        NSError *error = nil;
        BOOL ok = [weakSelf.database execSql:query
                                      values:nil
                                       error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:@"Unable to delete metadata"
                                     error:error];
        }
        
        // Then, insert the new metadata
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[weakSelf metadata]];
        ok = [weakSelf.database insertRecord:ZumeroIncrementalStoreMetadataTableName
                                      values:@{ ZumeroIncrementalStoreMetadataColumnName : data }
                                    inserted:nil
                                       error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:@"Unable to save metadata"
                                     error:error];
        }
        
        return ok;
    };
    
    return [self processTransaction:transaction database:weakSelf.database];
}

#pragma mark - Tables for entities

- (BOOL)createTableForEntity:(NSEntityDescription *)entity database:(ZumeroDB *)database
{
    // Skip sub-entities since the super-entities create columns for all their children
    if (entity.superentity) {
        return YES;
    }
    
//    DLog(@"initializing %@", [entity name]);
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSMutableDictionary *fields = [NSMutableDictionary dictionary];
        
        // Primary Key
        NSString *primaryKeyName = [weakSelf primaryKeyNameForEntity:entity];
        [fields addEntriesFromDictionary:@{ primaryKeyName : @{ @"type" : @"unique",
                                                                @"not_null" : @YES,
                                                                @"primary_key" : @YES } }];
        
        // Foreign Keys
        NSDictionary *foreignKeysDictionary = [weakSelf foreignKeysForEntity:entity];
        [fields addEntriesFromDictionary:foreignKeysDictionary];
        
        // Attributes
        NSDictionary *attributesDictionary = [weakSelf attributesForEntity:entity];
        [fields addEntriesFromDictionary:attributesDictionary];
        
        NSError *error = nil;
        NSString *tableName = [weakSelf tableNameForEntity:entity];
        BOOL ok = [database defineTable:tableName
                                 fields:fields
                                  error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to create %@ table", tableName]
                                     error:error];
        }
        return ok;
    };
    
    return [self processTransaction:transaction database:database];
}

- (NSDictionary *)foreignKeysForEntity:(NSEntityDescription *)entity
{
    NSMutableDictionary *foreignKeysDictionary = [NSMutableDictionary dictionary];
    NSDictionary *relationships = [entity relationshipsByName];
    [relationships enumerateKeysAndObjectsUsingBlock:^(id key, id relationship, BOOL *stop) {
        NSString *foreignKeyName = [self foreignKeyNameForRelationship:relationship];
        NSString *targetTableName = [self tableNameForEntity:[relationship destinationEntity]];
        
        // Don't add foreign keys for one-to-many relationships.
        // They are tracked in the database via the foreign key in the destination table
        // for their inverse many-to-one relationships.
        // Note that foreign keys are created for both sides of one-to-one relationships.
        if (! [relationship isToMany]) {
            [foreignKeysDictionary addEntriesFromDictionary: @{ foreignKeyName : @{ @"type" : @"reference",
                                                                     @"other_table" : targetTableName } }];
        }
    }];
    
    // Recursively add the foreign keys for the subentities
    for (NSEntityDescription *subentity in entity.subentities) {
        NSDictionary *foreignKeysForSubentity = [self foreignKeysForEntity:subentity];
        [foreignKeysDictionary addEntriesFromDictionary:foreignKeysForSubentity];
    }

    return foreignKeysDictionary;
}

- (NSDictionary *)attributesForEntity:(NSEntityDescription *)entity
{
    NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionary];
    NSDictionary *attributes = [entity attributesByName];
    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id attribute, BOOL *stop) {
        NSString *type = [self sqliteTypeForCoreDataAttribute:attribute];
        [attributesDictionary addEntriesFromDictionary: @{ key : @{ @"type" : type } }];
    }];
    
    // Recursively add the attributes for the subentities
    for (NSEntityDescription *subentity in entity.subentities) {
        NSDictionary *attributesForSubentity = [self attributesForEntity:subentity];
        [attributesDictionary addEntriesFromDictionary:attributesForSubentity];
    }

    return attributesDictionary;
}

- (NSString *)sqliteTypeForCoreDataAttribute:(NSAttributeDescription *)attribute
{
    NSAttributeType type = [attribute attributeType];
    
    // string
    if (type == NSStringAttributeType) {
        return @"text";
    }
    
    // real number
    else if (type == NSDoubleAttributeType ||
             type == NSFloatAttributeType) {
        return @"real";
    }
    
    // integer
    else if (type == NSInteger16AttributeType ||
             type == NSInteger32AttributeType ||
             type == NSInteger64AttributeType) {
        return @"int";
    }
    
    // boolean
    else if (type == NSBooleanAttributeType) {
        return @"int";
    }
    
    // date
    else if (type == NSDateAttributeType) {
        return @"int";
    }
    
    // blob
    else if (type == NSBinaryDataAttributeType) {
        return @"blob";
    }
    
    // The following types aren't handled:
    // NSUndefinedAttributeType
    // NSDecimalAttributeType
    // NSTransformableAttributeType
    // NSObjectIDAttributeType
    
    return nil;
}

- (NSString *)tableNameForEntity:(NSEntityDescription *)entity
{
    NSEntityDescription *targetEntity = entity;
    while ([targetEntity superentity] != nil) {
        targetEntity = [targetEntity superentity];
    }
    return [targetEntity name];
}

- (NSString *)insertRecordForEntity:(NSEntityDescription *)entity
{
    __weak __typeof(&*self)weakSelf = self;
    __block NSString *primaryKeyValue = nil;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSMutableDictionary *inserted = [NSMutableDictionary dictionary];
        NSString *primaryKeyName = [weakSelf primaryKeyNameForEntity:entity];
        [inserted setObject:[NSNull null] forKey:primaryKeyName];
        NSError *error = nil;
        NSString *tableName = [self tableNameForEntity:entity];
        NSDictionary *defaultValues = [self defaultValuesForEntity:entity];
        BOOL ok = [weakSelf.database insertRecord:tableName
                                           values:defaultValues
                                         inserted:inserted
                                            error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to create %@ object", [entity name]]
                                     error:error];
        } else {
            primaryKeyValue = [inserted objectForKey:primaryKeyName];
        }
        //        DLog(@"entity: %@, table: %@, primaryKeyName: %@, primaryKeyValue: %@", [entity name], tableName, primaryKeyName, primaryKeyValue);
        return ok;
    };
    
    if (! [self processTransaction:transaction database:self.database]) {
        return nil;
    };
    return primaryKeyValue;
}

- (NSDictionary *)defaultValuesForEntity:(NSEntityDescription *)entity
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    NSDictionary *attributes = [entity attributesByName];
    [attributes enumerateKeysAndObjectsUsingBlock:^(id attributeName, id attributeDescription, BOOL *stop) {
        id defaultValue = [attributeDescription defaultValue];
        //        DLog(@"entity: %@, property name: %@, value: %@", [entity name], attributeName, defaultValue);
        if (defaultValue) {
            [defaultValues addEntriesFromDictionary:@{ attributeName : defaultValue }];
        }
    }];
    if ([defaultValues count] > 0) {
        return [NSDictionary dictionaryWithDictionary:defaultValues];
    }
    return nil;
}

#pragma mark - Join tables for many-to-many relationships

- (BOOL)createJoinTablesForEntity:(NSEntityDescription *)entity database:(ZumeroDB *)database
{
    // Skip sub-entities since the super-entities should handle creating join tables for all their children.
    if (entity.superentity) {
        return YES;
    }
    
    NSMutableDictionary *relationships = [NSMutableDictionary dictionaryWithDictionary:[entity relationshipsByName]];
    for (NSEntityDescription *subentity in entity.subentities) {
        [relationships addEntriesFromDictionary:[subentity relationshipsByName]];
    }
    __block BOOL success = YES;
    [relationships enumerateKeysAndObjectsUsingBlock:^(id key, id relationship, BOOL *stop) {
        if ([relationship isToMany] && [[relationship inverseRelationship] isToMany]) {
            if (! [self createJoinTableForRelationship:relationship database:database]) {
                success = NO;
                *stop = YES;
                return;
            }
        }
    }];
    return success;
}

- (BOOL)createJoinTableForRelationship:(NSRelationshipDescription *)relationship database:(ZumeroDB *)database
{
    NSRelationshipDescription *inverseRelationship = [relationship inverseRelationship];
    ZAssert([relationship isToMany] && [inverseRelationship isToMany],
            @"Join tables can only be created for many-to-many relationships.");
    
//    DLog(@"TO-MANY: %@, inverse: %@", [relationship name], [[relationship inverseRelationship] name]);
    NSString *tableName = [self tableNameForRelationship:relationship];
// TODO: set this dynamically instead of hard-coding it
    NSString *databaseName = @"main";
    if (database != self.database) {
        databaseName = ZumeroIncrementalStoreTemporaryDatabaseName;
    }
    if ([database tableExists:tableName]) {
        return YES;
    }
    
    NSString *relationshipForeignKeyName = [self foreignKeyNameForRelationship:relationship];
    NSString *inverseForeignKeyName = [self foreignKeyNameForRelationship:inverseRelationship];
    
    // We're intentionally not establishing REFERENCES to the related tables and primary keys,
    // because if we do, we'll run into foreign key constraint violations during migrations,
    // since we can't guarantee that the related tables will be copied before the join tables are copied
    NSString *query = [NSString stringWithFormat:@"CREATE VIRTUAL TABLE %@.%@ USING zumero ( %@ TEXT, %@ TEXT, PRIMARY KEY (%@,%@) );",
                       databaseName,
                       tableName,
                       relationshipForeignKeyName,
                       inverseForeignKeyName,
                       relationshipForeignKeyName,
                       inverseForeignKeyName];

    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSError *error = nil;
        BOOL ok = [database execSql:query
                             values:nil
                              error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to create %@ table", tableName]
                                     error:error];
        }
        return ok;
    };
    
    return [self processTransaction:transaction database:database];
}

- (NSString *)tableNameForRelationship:(NSRelationshipDescription *)relationship
{
    NSRelationshipDescription *inverseRelationship = [relationship inverseRelationship];
    ZAssert([relationship isToMany] && [inverseRelationship isToMany],
            @"Join tables can only be created for many-to-many relationships.");
    
    NSString *sourceEntityTableName = [self tableNameForEntity:[relationship entity]];
    NSString *destinationEntityTableName = [self tableNameForEntity:[inverseRelationship entity]];
    
    // Arrange the table names alphabetically (case insensitive)
    NSRelationshipDescription *firstRelationship = relationship;
    NSRelationshipDescription *secondRelationship = inverseRelationship;
    if ([sourceEntityTableName caseInsensitiveCompare:destinationEntityTableName] == NSOrderedDescending) {
        firstRelationship = inverseRelationship;
        secondRelationship = relationship;
    }
    
    return [NSString stringWithFormat:@"%@_%@_to_%@_%@",
            [self tableNameForEntity:[firstRelationship entity]],
            [firstRelationship name],
            [self tableNameForEntity:[secondRelationship entity]],
            [secondRelationship name]];;
}

#pragma mark - Column names

- (NSString *)primaryKeyNameForEntity:(NSEntityDescription *)entity
{
    return [NSString stringWithFormat:@"%@PK", [[self tableNameForEntity:entity] lowercaseString]];
}

- (NSString *)foreignKeyNameForRelationship:(NSRelationshipDescription *)relationship
{
    return [self foreignKeyNameForRelationshipName:[relationship name]];
}

- (NSString *)foreignKeyNameForRelationshipName:(NSString *)relationshipName
{
    return [NSString stringWithFormat:@"%@FK", relationshipName];
}

#pragma mark - Migration methods

- (BOOL)migrateFromModel:(NSManagedObjectModel *)fromModel toModel:(NSManagedObjectModel *)toModel error:(NSError *__autoreleasing *)error
{
    BOOL __block success = YES;
    
    NSMappingModel *mappingModel = [NSMappingModel inferredMappingModelForSourceModel:fromModel destinationModel:toModel error:error];
    if (! mappingModel) {
        return NO;
    }
    
    // Create a database for the new model and add the metadata table
    success = [self initializeSchemaForModel:toModel database:self.temporaryDatabase];
    if (! success) {
        return NO;
    }

    // Grab entity snapshots
    NSDictionary *sourceEntities = [fromModel entitiesByName];
    NSDictionary *destinationEntities = [toModel entitiesByName];
    
    // Enumerate over entities
    for (NSEntityMapping *entityMapping in [mappingModel entityMappings]) {
        
        // Get names
        NSString *sourceEntityName = [entityMapping sourceEntityName];
        NSString *destinationEntityName = [entityMapping destinationEntityName];
//        DLog(@"sourceEntityName: %@", sourceEntityName);
//        DLog(@"destinationEntityName: %@", destinationEntityName);
//        DLog(@"entityMapping: %@", entityMapping);

        // Get entity descriptions
        NSEntityDescription *sourceEntity = [sourceEntities objectForKey:sourceEntityName];
        NSEntityDescription *destinationEntity = [destinationEntities objectForKey:destinationEntityName];
        
        // Get mapping type
        NSEntityMappingType type = [entityMapping mappingType];
        
        // Add a new entity from final snapshot
        if (type == NSAddEntityMappingType) {
            DLog(@"ADD ENTITY: %@", [entityMapping destinationEntityName]);
        }
        
        // Drop table for deleted entity
        else if (type == NSRemoveEntityMappingType) {
            DLog(@"REMOVE ENTITY: %@", [entityMapping sourceEntityName]);
// TODO: what if some of the properties from the entity being removed are mapped to an existing or new entity in the destination db?
        }
        
        // Change an entity
        else if (type == NSTransformEntityMappingType) {
            DLog(@"TRANSFORM ENTITY: %@", [entityMapping destinationEntityName]);
            // Copy the data from the old store to the new store according to the entity mapping
            success = [self copyTablesForSourceEntity:sourceEntity
                                    destinationEntity:destinationEntity
                                              mapping:entityMapping
                                                error:error];
        }
        
        // Copy an entity as-is
        else if (type == NSCopyEntityMappingType) {
            DLog(@"COPY ENTITY: %@", [entityMapping destinationEntityName]);
            [self copyTableForEntity:destinationEntity];
            
        } else {
            DLog(@"Warning: This Entity Mapping Type is not handled yet.");
            exit(-1);
        }
        
        if (!success) {
            break;
        }
    }

    [self.temporaryDatabase detach:error];
    
    if (success) {
        
        // Close the original database
        [self.database close];

        // Move the original database to a backup file, and move the temporary database to the original
        NSString *backupPath = [[self databasePath] stringByAppendingString:@".backup"];
        [[NSFileManager defaultManager] moveItemAtPath:[self databasePath] toPath:backupPath error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:[self temporaryDatabasePath] toPath:[self databasePath] error:nil];

        // Open the new database
        success = [self initializeDatabase:self.database];
        
    } else {
        
        // If migration failed, delete the temporary database
        [[NSFileManager defaultManager] removeItemAtPath:[self temporaryDatabasePath] error:nil];
    }
    
    return success;
}

- (BOOL)copyTable:(NSString *)tableName
{
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@.%@ SELECT * FROM main.%@",
                       ZumeroIncrementalStoreTemporaryDatabaseName,
                       tableName,
                       tableName];
//    DLog(@"%@", query);
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSError *error = nil;
        BOOL ok = [weakSelf.database execSql:query
                                      values:nil
                                       error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to copy table: %@", tableName]
                                     error:error];
        }
        return ok;
    };
    
    return [self processTransaction:transaction database:weakSelf.database];
}

- (BOOL)copyTableForEntity:(NSEntityDescription *)entity
{
    // Skip sub-entities since the super-entities should handle copying join tables for all their children.
    if (entity.superentity) {
        return YES;
    }
    
    NSString *tableName = [self tableNameForEntity:entity];
    return [self copyTable:tableName];
}

- (BOOL)copyTablesForSourceEntity:(NSEntityDescription *)sourceEntity
                destinationEntity:(NSEntityDescription *)destinationEntity
                          mapping:(NSEntityMapping *)mapping
                            error:(NSError *__autoreleasing *)error
{
//    DLog(@"sourceEntity: %@", sourceEntity);
//    DLog(@"destinationEntity: %@", destinationEntity);
//    DLog(@"mapping: %@", mapping);
    BOOL success = YES;
    NSString *sourceTableName = [self tableNameForEntity:sourceEntity];
    NSString *destinationTableName = [self tableNameForEntity:destinationEntity];
    
    NSMutableArray *sourceColumns = [NSMutableArray array];
    NSMutableArray *destinationColumns = [NSMutableArray array];
    
    NSDictionary *sourceRelationships = [sourceEntity relationshipsByName];
    NSDictionary *destinationRelationships = [destinationEntity relationshipsByName];

    // We need to copy the to-many relationships for all entities
    for (NSPropertyMapping *relationshipMapping in [mapping relationshipMappings]) {
        NSString *relationshipName = [relationshipMapping name];
        NSExpression *expression = [relationshipMapping valueExpression];
        if (expression) {
            NSRelationshipDescription *sourceRelationship = [sourceRelationships objectForKey:[[[expression arguments] objectAtIndex:0] constantValue]];
            NSRelationshipDescription *destinationRelationship = [destinationRelationships objectForKey:relationshipName];
            if ([destinationRelationship isToMany]) {
                
                if ([[destinationRelationship inverseRelationship] isToMany]) {
                    
                    // Copy the join table for many-to-many relationships
                    // This will get called twice: once for each side of the relationship
                    // The second call will be a no-op, since the same records will already exist in the join table
                    success = [self copyJoinTableForSourceRelationship:sourceRelationship
                                               destinationRelationship:destinationRelationship];
                    
                } else {
                    // Don't do anything for one-to-many relationships,
                    // since the foreign keys in the related entity will be copied
                }
            }
        }
    }

    // We don't need to copy the data for the subentities,
    // since the superentity table will include the data for all subentities
    if (success && ! destinationEntity.superentity) {
        
        // Primary key
        NSString *sourcePrimaryKeyName = [self primaryKeyNameForEntity:sourceEntity];
        [sourceColumns addObject:sourcePrimaryKeyName];
        NSString *destinationPrimaryKeyName = [self primaryKeyNameForEntity:destinationEntity];
        [destinationColumns addObject:destinationPrimaryKeyName];
        
        // Attributes
//        DLog(@"Attribute Mappings: \n%@", [mapping attributeMappings]);
        for (NSPropertyMapping *attributeMapping in [mapping attributeMappings]) {
            NSExpression *expression = [attributeMapping valueExpression];
            if (expression) {
                NSString *sourceAttributeName = [[[expression arguments] objectAtIndex:0] constantValue];
                NSString *destinationAttributeName = [attributeMapping name];
                [sourceColumns addObject:sourceAttributeName];
                [destinationColumns addObject:destinationAttributeName];
            }
        }
        
        // Relationships
//        DLog(@"Relationship Mappings: \n%@", [mapping relationshipMappings]);
        for (NSPropertyMapping *relationshipMapping in [mapping relationshipMappings]) {
            NSString *relationshipName = [relationshipMapping name];
            NSExpression *expression = [relationshipMapping valueExpression];
            if (expression) {
                NSRelationshipDescription *destinationRelationship = [destinationRelationships objectForKey:relationshipName];
                if ([destinationRelationship isToMany]) {
                    
                    // To-many relationships were already handled in the join table code above
                    
                } else {
                    
                    // Copy the foreign keys for one-to-one and many-to-one relationships
                    NSString *sourceForeignKeyName = [self foreignKeyNameForRelationshipName:[[[expression arguments] objectAtIndex:0] constantValue]];
                    NSString *destinationForeignKeyName = [self foreignKeyNameForRelationshipName:[relationshipMapping name]];
                    [sourceColumns addObject:sourceForeignKeyName];
                    [destinationColumns addObject:destinationForeignKeyName];
                }
            }
        }
        
        NSString *query = [NSString stringWithFormat:@"INSERT INTO %@.%@ (%@) SELECT %@ FROM main.%@",
                           ZumeroIncrementalStoreTemporaryDatabaseName,
                           destinationTableName,
                           [destinationColumns componentsJoinedByString:@", "],
                           [sourceColumns componentsJoinedByString:@", "],
                           sourceTableName];
//        DLog(@"query: %@", query);
        
        __weak __typeof(&*self)weakSelf = self;
        ZumeroTransactionBlock transaction = ^ BOOL {
            NSError *error = nil;
            BOOL ok = [weakSelf.database execSql:query
                                          values:nil
                                           error:&error];
            if (! ok) {
                [weakSelf reportErrorWithTitle:@"Error"
                                   description:[NSString stringWithFormat:@"Unable to copy %@ table to %@ table", sourceTableName, destinationTableName]
                                         error:error];
            }
            return ok;
        };
        
        success = [self processTransaction:transaction database:weakSelf.database];
    }
    
    return success;
}

- (BOOL)copyJoinTableForSourceRelationship:(NSRelationshipDescription *)sourceRelationship
                   destinationRelationship:(NSRelationshipDescription *)destinationRelationship
{
    NSString *sourceTableName = [self tableNameForRelationship:sourceRelationship];
    NSString *destinationTableName = [self tableNameForRelationship:destinationRelationship];
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@.%@ SELECT * FROM main.%@",
                       ZumeroIncrementalStoreTemporaryDatabaseName,
                       destinationTableName,
                       sourceTableName];
//    DLog(@"%@", query);
    
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        NSError *error = nil;
        BOOL ok = [weakSelf.database execSql:query
                                      values:nil
                                       error:&error];
        if (! ok) {
            [weakSelf reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to copy table: %@ to table: %@", sourceTableName, destinationTableName]
                                     error:error];
        }
        return ok;
    };
    
    return [self processTransaction:transaction database:weakSelf.database];
}

#pragma mark - Fetch request methods

- (id)executeFetchRequest:(NSFetchRequest *)fetchRequest
              withContext:(NSManagedObjectContext *)context
                    error:(NSError *__autoreleasing *)error
{
    if (fetchRequest.resultType != NSManagedObjectResultType &&
        fetchRequest.resultType != NSManagedObjectIDResultType) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"Unsupported result type for request %@", fetchRequest];
            *error = [NSError errorWithDomain:[self type]
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return nil;
    }
    
    NSEntityDescription *entity = [fetchRequest entity];
    NSString *primaryKeyName = [self primaryKeyNameForEntity:entity];
    NSString *tableName = [self tableNameForEntity:entity];
    
    NSDictionary *whereDictionary = [self whereClauseWithFetchRequest:fetchRequest];
    DLog(@"WHERE: %@", whereDictionary);
    NSString *whereClause = whereDictionary[@"query"];
    NSString *orderClause = [self orderClauseWithFetchRequest:fetchRequest entity:entity];
    NSString *limitClause = ([fetchRequest fetchLimit] > 0 ? [NSString stringWithFormat:@" LIMIT %ld", (unsigned long)[fetchRequest fetchLimit]] : @"");

    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@%@%@%@",
                       primaryKeyName,
                       tableName,
                       whereClause,
                       orderClause,
                       limitClause];
    DLog(@"query: %@", query);

    NSArray *values = [self valuesForBindings:whereDictionary[@"bindings"]];
    DLog(@"values: %@", values);

    NSArray *rows = nil;
    BOOL ok = [self.database selectSql:query values:values rows:&rows error:error];
    
    NSMutableArray *results = [NSMutableArray array];
    if (ok) {
        for (NSDictionary *dictionary in rows) {
            NSString *primaryKey = [dictionary objectForKey:primaryKeyName];
            NSManagedObjectID *objectID = [self newObjectIDForEntity:entity referenceObject:primaryKey];
            if (fetchRequest.resultType == NSManagedObjectIDResultType) {
                [results addObject:objectID];
            } else if (fetchRequest.resultType == NSManagedObjectResultType) {
                id object = [context objectWithID:objectID];
                [results addObject:object];
            }
        }
        
        // If the SQL query above can't handle specific predicates or sort descriptors,
        // we could handle them in memory instead via the following code
//        if (fetchRequest.predicate) {
//            [results filterUsingPredicate:fetchRequest.predicate];
//        }
//        if (fetchRequest.sortDescriptors) {
//            [results sortUsingDescriptors:fetchRequest.sortDescriptors];
//        }
    }
//    DLog(@"# of objects: %d", [results count]);
    
    return results;
}

- (id)executeSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
                    withContext:(NSManagedObjectContext *)context
                          error:(NSError *__autoreleasing *)error
{
    DLog(@"");
    __weak __typeof(&*self)weakSelf = self;
    ZumeroTransactionBlock transaction = ^ BOOL {
        BOOL insert = [weakSelf saveInsertedObjects:[saveChangesRequest insertedObjects] error:error];
        BOOL update = [weakSelf saveUpdatedObjects:[saveChangesRequest updatedObjects] error:error];
        BOOL delete = [weakSelf saveDeletedObjects:[saveChangesRequest deletedObjects] error:error];
        return (BOOL)(insert && update && delete);
    };
    BOOL success = [self processTransaction:transaction database:self.database];
    if (success) {
        return [NSArray array];
    }
    return nil;
}

- (BOOL)saveInsertedObjects:(NSSet *)objects error:(NSError *__autoreleasing *)error
{
    DLog(@"# of objects: %d", [objects count]);
    // Since we already inserted the objects in the obtainPermanentIDsForObjects: method,
    // we can just update the values of the existing objects
    return [self saveUpdatedObjects:objects error:error];
}

- (BOOL)saveUpdatedObjects:(NSSet *)objects error:(NSError *__autoreleasing *)error
{
    // Loop through the objects
    DLog(@"# of objects: %d", [objects count]);
    for (NSManagedObject *object in objects) {
        NSString *primaryKeyName = [self primaryKeyNameForEntity:[object entity]];
        NSString *primaryKeyValue = [self referenceObjectForObjectID:[object objectID]];

        // Loop through the changed values
        NSDictionary *changedValues = [object changedValues];
        NSDictionary *properties = [[object entity] propertiesByName];
        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        [changedValues enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            id property = [properties objectForKey:key];
            if ([property isKindOfClass:[NSAttributeDescription class]]) {
                
                // Attributes
                [values setObject:value forKey:key];
                
            } else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
                
                // Relationships
                NSRelationshipDescription *relationship = (NSRelationshipDescription *)property;
                NSRelationshipDescription *inverseRelationship = [relationship inverseRelationship];
                if ([relationship isToMany]) {
                    
                    // Many-to-many relationships
                    // We only need to handle many-to-many relationships here, since one-to-many relationships will be
                    // saved when the object on the other side of the relationship saves its many-to-one relationship
                    if ([inverseRelationship isToMany]) {
//                        DLog(@"SAVING TO-MANY: %@, inverse: %@", [relationship name], [inverseRelationship name]);
                        NSString *tableName = [self tableNameForRelationship:relationship];
                        NSString *relationshipForeignKeyName = [self foreignKeyNameForRelationship:relationship];
                        NSString *inverseForeignKeyName = [self foreignKeyNameForRelationship:inverseRelationship];
                        
                        // First, delete all related records from the join table
                        // This is necessary to handle related objects that were removed from the many-to-many relationship
                        NSString *inverseForeignKeyValue = [self referenceObjectForObjectID:[object objectID]];
                        BOOL ok = [self.database delete:tableName
                                               criteria:@{ inverseForeignKeyName : inverseForeignKeyValue }
                                                  error:error];
                        if (! ok) {
                            [self reportErrorWithTitle:@"Error"
                                           description:[NSString stringWithFormat:@"Unable to delete many-to-many relationship: %@ for object: %@", [relationship name], NSStringFromClass([object class])]
                                                 error:*error];
                        }

                        // Loop through each related object in the set
                        id relatedObjects = [object valueForKey:relationship.name];
                        for (NSManagedObject *relatedObject in relatedObjects) {
                            NSString *relationshipForeignKeyValue = [self referenceObjectForObjectID:[relatedObject objectID]];
//                            DLog(@"relationshipForeignKeyName: %@, relationshipForeignKeyValue: %@, inverseForeignKeyName: %@, inverseForeignKeyValue: %@", relationshipForeignKeyName, relationshipForeignKeyValue, inverseForeignKeyName, inverseForeignKeyValue);

                            // Then insert the appropriate records
                            ok = [self.database insertRecord:tableName
                                                      values:@{ relationshipForeignKeyName : relationshipForeignKeyValue, inverseForeignKeyName : inverseForeignKeyValue }
                                                    inserted:nil
                                                       error:error];
                            if (! ok) {
                                [self reportErrorWithTitle:@"Error"
                                               description:[NSString stringWithFormat:@"Unable to save many-to-many relationship: %@ for object: %@", [relationship name], NSStringFromClass([object class])]
                                                     error:*error];
                            }
                        }
                    }
                    
                } else {
                    
                    // One-to-one and many-to-one relationships
                    NSString *foreignKeyName = [self foreignKeyNameForRelationship:relationship];
                    
                    // We need to check for NSNull to handle a relationship being nullified
                    id foreignKeyValue = [NSNull null];
                    if (value != [NSNull null]) {
                        foreignKeyValue = [self referenceObjectForObjectID:[(NSManagedObject *)value objectID]];
                    }
                    [values setObject:foreignKeyValue forKey:foreignKeyName];
//                    DLog(@"relationship: %@, key: %@, value:%@", [property name], foreignKeyName, foreignKeyValue);
                }
            }
        }];
        
        // Write to the database if there are any values in the values dictionary
        if ([values count] > 0) {
            NSString *tableName = [self tableNameForEntity:[object entity]];
//            DLog(@"tableName: %@, primaryKeyName: %@, primaryKeyValue: %@, values: %@", tableName, primaryKeyName, primaryKeyValue, values);
            BOOL ok = [self.database update:tableName
                                   criteria:@{ primaryKeyName : primaryKeyValue }
                                     values:values
                                      error:error];
            if (! ok) {
                [self reportErrorWithTitle:@"Error"
                               description:[NSString stringWithFormat:@"Unable to save object: %@", NSStringFromClass([object class])]
                                     error:*error];
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)saveDeletedObjects:(NSSet *)objects error:(NSError *__autoreleasing *)error
{
    // Loop through the objects
    DLog(@"# of objects: %d", [objects count]);
    BOOL success = YES;
    for (NSManagedObject *object in objects) {
        NSString *primaryKeyName = [self primaryKeyNameForEntity:[object entity]];
        NSString *primaryKeyValue = [self referenceObjectForObjectID:[object objectID]];
        NSError *error = nil;
        NSString *tableName = [self tableNameForEntity:[object entity]];
        BOOL ok = [self.database delete:tableName
                               criteria:@{ primaryKeyName : primaryKeyValue }
                                  error:&error];
        if (! ok) {
            success = NO;
            [self reportErrorWithTitle:@"Error"
                           description:[NSString stringWithFormat:@"Unable to delete object: %@", NSStringFromClass([object class])]
                                 error:error];
        }
    }
    return success;
}

#pragma mark - Sync

- (BOOL)syncWithCompletionBlock:(ZumeroSyncCompletionBlock)completionBlock
{
    self.syncCompletionBlock = completionBlock;
    
    NSError *error = nil;
    return [self.database sync:[[self class] scheme] user:[[self class] username] password:[[self class] password] error:&error];
}

#pragma mark - <ZumeroDBDelegate>

- (void)syncFail:(NSString *)dbname err:(NSError *)error
{
//    DLog(@"syncFail");
//	[self reportErrorWithTitle:@"syncFail"
//                   description:@"Zumero sync failed"
//                         error:error];
    BOOL success = NO;
    self.syncCompletionBlock(success, error);
}

- (void)syncSuccess:(NSString *)dbname
{
//    DLog(@"syncSuccess");
    BOOL success = YES;
    NSError *error = nil;
    self.syncCompletionBlock(success, error);
}

#pragma mark - Where clause

/*
 
 The family of whereClauseWithFetchRequest: methods will return a dictionary
 with the following schema:
 
 {
 "query": "query string with ? parameters",
 "bindings": [
 "array",
 "of",
 "bindings"
 ]
 }
 
 */
- (NSDictionary *)whereClauseWithFetchRequest:(NSFetchRequest *)request
{
    NSDictionary *result = [self recursiveWhereClauseWithFetchRequest:request predicate:[request predicate]];
    if ([(NSString*)result[@"query"] length] > 0) {
        NSMutableDictionary *mutableResult = [result mutableCopy];
        mutableResult[@"query"] = [NSString stringWithFormat:@" WHERE %@", result[@"query"]];
        result = mutableResult;
    }
    return result;
}

- (NSDictionary *)recursiveWhereClauseWithFetchRequest:(NSFetchRequest *)request predicate:(NSPredicate *)predicate
{
    static NSDictionary *operators = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        operators = @{
                      @(NSEqualToPredicateOperatorType)              : @{ @"operator" : @"=",      @"format" : @"%@" },
                      @(NSNotEqualToPredicateOperatorType)           : @{ @"operator" : @"!=",     @"format" : @"%@" },
                      @(NSContainsPredicateOperatorType)             : @{ @"operator" : @"LIKE",   @"format" : @"%%%@%%" },
                      @(NSBeginsWithPredicateOperatorType)           : @{ @"operator" : @"LIKE",   @"format" : @"%@%%" },
                      @(NSEndsWithPredicateOperatorType)             : @{ @"operator" : @"LIKE",   @"format" : @"%%%@" },
                      @(NSLikePredicateOperatorType)                 : @{ @"operator" : @"LIKE",   @"format" : @"%@" },
                      @(NSMatchesPredicateOperatorType)              : @{ @"operator" : @"REGEXP", @"format" : @"%@" },
                      @(NSInPredicateOperatorType)                   : @{ @"operator" : @"IN",     @"format" : @"(%@)" },
                      @(NSLessThanPredicateOperatorType)             : @{ @"operator" : @"<",      @"format" : @"%@" },
                      @(NSLessThanOrEqualToPredicateOperatorType)    : @{ @"operator" : @"<=",     @"format" : @"%@" },
                      @(NSGreaterThanPredicateOperatorType)          : @{ @"operator" : @">",      @"format" : @"%@" },
                      @(NSGreaterThanOrEqualToPredicateOperatorType) : @{ @"operator" : @">=",     @"format" : @"%@" }
                      };
    });
    
    NSString *query = @"";
    NSMutableArray *bindings = [NSMutableArray array];
    
    if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        
        NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate*)predicate;
        
        // Get subpredicates
        NSMutableArray *queries = [NSMutableArray array];
        [compoundPredicate.subpredicates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *result = [self recursiveWhereClauseWithFetchRequest:request predicate:obj];
            [queries addObject:[result objectForKey:@"query"]];
            [bindings addObjectsFromArray:[result objectForKey:@"bindings"]];
        }];
        
        // Build query
        if (compoundPredicate.compoundPredicateType == NSAndPredicateType) {
            query = [NSString stringWithFormat:@"(%@)", [queries componentsJoinedByString:@" AND "]];
        } else if (compoundPredicate.compoundPredicateType == NSOrPredicateType) {
            query = [NSString stringWithFormat:@"(%@)", [queries componentsJoinedByString:@" OR "]];
        }
        
    } else if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        
        NSComparisonPredicate *comparisonPredicate = (NSComparisonPredicate*)predicate;
        
        NSNumber *type = @(comparisonPredicate.predicateOperatorType);
        NSDictionary *operator = [operators objectForKey:type];
        
        id leftOperand = nil;
        id leftBindings = nil;
        [self parseExpression:comparisonPredicate.leftExpression
                  inPredicate:comparisonPredicate
               inFetchRequest:request
                     operator:operator
                      operand:&leftOperand
                     bindings:&leftBindings];
        
        id rightOperand = nil;
        id rightBindings = nil;
        [self parseExpression:comparisonPredicate.rightExpression
                  inPredicate:comparisonPredicate
               inFetchRequest:request
                     operator:operator
                      operand:&rightOperand
                     bindings:&rightBindings];
        
        // Build result and return
        NSMutableArray *comparisonBindings = [NSMutableArray arrayWithCapacity:2];
        if (leftBindings)  [comparisonBindings addObject:leftBindings];
        if (rightBindings) [comparisonBindings addObject:rightBindings];
        query = [NSString stringWithFormat:@"%@ %@ %@",
                 leftOperand,
                 [operator objectForKey:@"operator"],
                 rightOperand];
        bindings = [[comparisonBindings cmdFlatten] mutableCopy];
    }
    
    return @{ @"query": query,
              @"bindings": bindings };
}

- (NSArray *)valuesForBindings:(NSArray *)bindings
{
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:[bindings count]];
    for (id object in bindings) {
        if ([object isKindOfClass:[NSManagedObjectID class]]) {
            [values addObject:[self referenceObjectForObjectID:object]];
        } else if ([object isKindOfClass:[NSManagedObject class]]) {
            NSManagedObjectID *objectID = [object objectID];
            [values addObject:[self referenceObjectForObjectID:objectID]];
        } else {
            [values addObject:object];
        }
    }
    return [NSArray arrayWithArray:values];
}

- (void)parseExpression:(NSExpression *)expression
            inPredicate:(NSComparisonPredicate *)predicate
         inFetchRequest:(NSFetchRequest *)request
               operator:(NSDictionary *)operator
                operand:(id *)operand
               bindings:(id *)bindings
{
    NSExpressionType type = [expression expressionType];
    
    id value = nil;
    
    // key path expressed as function expression
    if (type == NSFunctionExpressionType) {
        NSString *methodString = NSStringFromSelector(@selector(valueForKeyPath:));
        
        if ([[expression function] isEqualToString:methodString]) {
            NSExpression *argumentExpression;
            argumentExpression = [[expression arguments] objectAtIndex:0];
            
            if ([argumentExpression expressionType] == NSConstantValueExpressionType) {
                value = [argumentExpression constantValue];
                type = NSKeyPathExpressionType;
            }
        }
    }
    
    // reference a column in the query
    NSEntityDescription *entity = [request entity];
    if (type == NSKeyPathExpressionType) {
        if (value == nil) {
            value = [expression keyPath];
        }
        NSDictionary *properties = [entity propertiesByName];
        id property = [properties objectForKey:value];
        if ([property isKindOfClass:[NSRelationshipDescription class]]) {
            value = [self foreignKeyNameForRelationship:property];
        }
        if (property == nil && [value rangeOfString:@"."].location != NSNotFound) {
            // We have a join table property, we need to rewrite the query.
            NSArray *pathComponents = [value componentsSeparatedByString:@"."];
            value = [NSString stringWithFormat:@"%@.%@",
                     [self joinedTableNameForComponents:pathComponents],
                     [pathComponents lastObject]];
            
        }
        *operand = value;
    } else if (type == NSEvaluatedObjectExpressionType) {
        NSString *primaryKeyName = [self primaryKeyNameForEntity:entity];
        *operand = primaryKeyName;
    } else if (type == NSConstantValueExpressionType) {
        // a value to be bound to the query
        value = [expression constantValue];
        if ([value isKindOfClass:[NSSet class]]) {
            NSUInteger count = [value count];
            NSArray *parameters = [NSArray cmdArrayWithObject:@"?" times:count];
            *bindings = [value allObjects];
            *operand = [NSString stringWithFormat:
                        [operator objectForKey:@"format"],
                        [parameters componentsJoinedByString:@", "]];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSUInteger count = [value count];
            NSArray *parameters = [NSArray cmdArrayWithObject:@"?" times:count];
            *bindings = value;
            *operand = [NSString stringWithFormat:
                        [operator objectForKey:@"format"],
                        [parameters componentsJoinedByString:@", "]];
        } else if ([value isKindOfClass:[NSString class]]) {
            if ([predicate options] & NSCaseInsensitivePredicateOption) {
                *operand = @"UPPER(?)";
                *bindings = [NSString stringWithFormat:
                             [operator objectForKey:@"format"],
                             [value uppercaseString]];
            } else {
                *operand = @"?";
                *bindings = [NSString stringWithFormat:
                             [operator objectForKey:@"format"],
                             value];
            }
        } else {
            *bindings = value;
            *operand = @"?";
        }
    } else {
        // unsupported type
        NSLog(@"%s Unsupported expression type %ld", __PRETTY_FUNCTION__, (unsigned long)type);
    }
}

- (NSString *)joinedTableNameForComponents:(NSArray *)componentsArray
{
    assert(componentsArray.count > 0);
    NSString *tableName = [[componentsArray subarrayWithRange:NSMakeRange(0, componentsArray.count - 1)] componentsJoinedByString:@"."];
    return [NSString stringWithFormat:@"[%@]", tableName];
}

- (NSString *)orderClauseWithFetchRequest:(NSFetchRequest *)fetchRequest entity:(NSEntityDescription *)entity
{
    NSArray *descriptors = [fetchRequest sortDescriptors];
    NSString *order = @"";
    
    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:[descriptors count]];
    [descriptors enumerateObjectsUsingBlock:^(NSSortDescriptor *desc, NSUInteger idx, BOOL *stop) {
        // We throw an exception in the join if the key is more than one relationship deep.
        // We do need to detect the relationship though to know what table to prefix the key with.
        NSString *tableName = [self tableNameForEntity:fetchRequest.entity];
        NSString *key = [desc key];
        if ([desc.key rangeOfString:@"."].location != NSNotFound) {
            NSArray *components = [desc.key componentsSeparatedByString:@"."];
            tableName = [self joinedTableNameForComponents:components];
            key = [components lastObject];
        }
        [columns addObject:[NSString stringWithFormat:@"%@.%@ %@", tableName, key, ([desc ascending]) ? @"ASC" : @"DESC"]];
    }];
    if (columns.count) {
        order = [NSString stringWithFormat:@" ORDER BY %@", [columns componentsJoinedByString:@", "]];
    }
    return order;
}

#pragma mark - Miscellaneous helper methods

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)databasePath
{
    return [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:[[self class] databaseFilename]];
}

- (NSString *)temporaryDatabasePath
{
    return [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:ZumeroIncrementalStoreTemporaryDatabaseName];
}

- (void)reportErrorWithTitle:(NSString *)title description:(NSString *)description error:(NSError *)error
{
	NSString *msg = description;
	
	if (error) {
		msg = [NSString stringWithFormat:@"%@:\n\n%@", description, [error description]];
	}
	
    // Log the error to the console in case the app exits before displaying the alert to the user
    DLog(@"%@: %@", title, msg);
    
    // You can uncomment this for debbugging
    // TODO: Add an #ifdef for a Mac alert dialog later
//	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
//													message:msg
//												   delegate:nil
//										  cancelButtonTitle:@"OK"
//										  otherButtonTitles:nil];
//	[alert show];
}

- (BOOL)processTransaction:(ZumeroTransactionBlock)transaction database:(ZumeroDB *)database
{
    NSError *error = nil;
    BOOL ok = [database beginTX:&error];
    if (! ok) {
        [self reportErrorWithTitle:@"Error"
                       description:@"Unable to begin transaction"
                             error:error];
    }
    
    if (ok) {
        // Transaction errors are handled within the transaction block
        ok = transaction();
    }
    
    if (ok) {
        ok = [database commitTX:&error];
    }
    if (! ok) {
        [self reportErrorWithTitle:@"Error"
                       description:@"Unable to commit transaction"
                             error:error];
        // If any part of the transaction failed, we need to abort the transaction
        [database abortTX:&error];
    }
    return ok;
}

@end
