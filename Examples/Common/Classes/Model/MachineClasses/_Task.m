// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Task.m instead.

#import "_Task.h"


const struct TaskAttributes TaskAttributes = {
	.dueDate = @"dueDate",
	.name = @"name",
	.priority = @"priority",
};



const struct TaskRelationships TaskRelationships = {
	.assistants = @"assistants",
	.manager = @"manager",
	.photo = @"photo",
	.project = @"project",
};






@implementation TaskID
@end

@implementation _Task

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Task";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Task" inManagedObjectContext:moc_];
}

- (TaskID*)objectID {
	return (TaskID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"priorityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"priority"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic dueDate;






@dynamic name;






@dynamic priority;



- (int64_t)priorityValue {
	NSNumber *result = [self priority];
	return [result longLongValue];
}


- (void)setPriorityValue:(int64_t)value_ {
	[self setPriority:@(value_)];
}


- (int64_t)primitivePriorityValue {
	NSNumber *result = [self primitivePriority];
	return [result longLongValue];
}

- (void)setPrimitivePriorityValue:(int64_t)value_ {
	[self setPrimitivePriority:@(value_)];
}





@dynamic assistants;

	
- (NSMutableSet*)assistantsSet {
	[self willAccessValueForKey:@"assistants"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"assistants"];
  
	[self didAccessValueForKey:@"assistants"];
	return result;
}
	

@dynamic manager;

	

@dynamic photo;

	

@dynamic project;

	






@end




