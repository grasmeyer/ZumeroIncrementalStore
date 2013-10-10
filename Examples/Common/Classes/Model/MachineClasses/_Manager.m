// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Manager.m instead.

#import "_Manager.h"


const struct ManagerAttributes ManagerAttributes = {
	.title = @"title",
};



const struct ManagerRelationships ManagerRelationships = {
	.tasks = @"tasks",
};






@implementation ManagerID
@end

@implementation _Manager

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Manager" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Manager";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Manager" inManagedObjectContext:moc_];
}

- (ManagerID*)objectID {
	return (ManagerID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic title;






@dynamic tasks;

	
- (NSMutableSet*)tasksSet {
	[self willAccessValueForKey:@"tasks"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tasks"];
  
	[self didAccessValueForKey:@"tasks"];
	return result;
}
	






@end




