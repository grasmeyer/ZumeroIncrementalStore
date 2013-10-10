#import "ModelObject.h"

@interface ModelObject()

@property (nonatomic) NSMutableDictionary *objectCache;

@end


@implementation ModelObject

@synthesize objectCache;

- (id)duplicateWithParent:(id)parent
{
	// Initialize the lookup dictionary. This will be used to make sure that unique objects are not duplicated
	self.objectCache = [NSMutableDictionary dictionary];

    id newObject = [NSEntityDescription insertNewObjectForEntityForName:[[self entity] name] inManagedObjectContext:self.managedObjectContext];
    
    [self copyPropertiesFromObject:self toObject:newObject parentEntityName:[[parent entity] name]];
    
    if (parent) {
        NSRelationshipDescription *parentRelationship = [[[self entity] relationshipsWithDestinationEntity:[parent entity]] firstObject];
        NSString *parentRelationshipName = [parentRelationship name];
        [newObject setValue:parent forKey:parentRelationshipName];
    }
    
    return newObject;
}

- (void)copyPropertiesFromObject:(NSManagedObject *)oldObject
                        toObject:(NSManagedObject *)newObject
                parentEntityName:(NSString *)parentEntityName
{
	// First, copy the attributes from the oldObject to the newObject
	NSString *entityName = [[oldObject entity] name];
	NSArray *attributeKeys = [[[oldObject entity] attributesByName] allKeys];
	NSDictionary *attributes = [oldObject dictionaryWithValuesForKeys:attributeKeys];
	[newObject setValuesForKeysWithDictionary:attributes];
	
	// Second, copy the relationships
	NSDictionary *relationships = [[oldObject entity] relationshipsByName];
	for (NSString *relationshipName in [relationships allKeys]) {
//        DLog(@"DUPLICATING entity: %@, relationship: %@", entityName, relationshipName);
		NSRelationshipDescription *relationship = [relationships valueForKey:relationshipName];
		
		// If the relationship points to the parent object, don't copy the parent object
		NSString *destinationEntityName = [[relationship destinationEntity] name];
		if ([destinationEntityName isEqualToString:parentEntityName]) continue;
		
        // If the delete rule of the relationship is NSNullifyDeleteRule, then the related child object should be unique, so it won't be duplicated
        BOOL objectMustBeUnique = NO;
        if ([relationship deleteRule] == NSNullifyDeleteRule) {
            objectMustBeUnique = YES;
        }
        
        // You can override the default behavior above by setting the "duplicate" key to YES or NO
        // in the userInfo dictionary for any relationship in the Core Data Model Editor in Xcode
        NSDictionary *userInfo = [relationship userInfo];
        NSNumber *duplicateFlag = [userInfo valueForKey:@"duplicate"];
        if (duplicateFlag) {
//            DLog(@"%@, duplicate: %d", [relationship userInfo], [duplicateFlag boolValue]);
            if ([duplicateFlag boolValue]) {
                objectMustBeUnique = NO;
            } else {
                if ([[relationship inverseRelationship] isToMany]) {
                    objectMustBeUnique = YES;
                } else {
                    DLog(@"WARNING: Related objects must always be duplicated for one-to-one and one-to-many relationships. Otherwise the related object would lose its relationship to the original parent object. You should modify the duplicate key in the userInfo for the %@ relationship in the %@ entity in your Core Data model.", [relationship name], [[relationship entity] name]);
                    objectMustBeUnique = NO;
                }
            }
        }
        
        id oldDestinationObject = nil;
		if ([relationship isToMany]) {
            
			// To-Many relationships
			NSMutableSet *newDestinationSet = [NSMutableSet set];
			for (oldDestinationObject in [oldObject valueForKey:relationshipName]) {
                id newDestinationObject = [self associateObject:oldDestinationObject parent:entityName unique:objectMustBeUnique];
				[newDestinationSet addObject:newDestinationObject];
//                DLog(@"newDestinationObject: %@", newDestinationObject);
			}
			[newObject setValue:newDestinationSet forKey:relationshipName];
            
		} else {
            
			// To-One relationships
			oldDestinationObject = [oldObject valueForKey:relationshipName];
			if (!oldDestinationObject) continue;
            id newDestinationObject = [self associateObject:oldDestinationObject parent:entityName unique:objectMustBeUnique];
			[newObject setValue:newDestinationObject forKey:relationshipName];
		}
	}
}

- (id)associateObject:(NSManagedObject *)object parent:(NSString *)parent unique:(BOOL)objectMustBeUnique
{
    // First, see if we already created this object
    id newDestinationObject = objectCache[[object objectID]];
    if (newDestinationObject) {
        DLog(@"lookup dictionary was used");
        return newDestinationObject;
    }
    
	// Associate a child object with its parent object
	if (objectMustBeUnique) {
        
        // If the child object must be unique just point to the existing child object
		objectCache[[object objectID]] = object;
		return object;
        
	} else {
        
		// Otherwise, insert a new object for the child entity
        NSString *entityName = [[object entity] name];
		id newDestinationObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
		objectCache[[object objectID]] = newDestinationObject;
		
		// Recursively copy the attributes and relationships of the new child object
		[self copyPropertiesFromObject:object toObject:newDestinationObject parentEntityName:parent];
		return newDestinationObject;
	}
}

@end
