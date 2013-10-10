// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Assistant.m instead.

#import "_Assistant.h"


const struct AssistantAttributes AssistantAttributes = {
	.hourlyRate = @"hourlyRate",
};



const struct AssistantRelationships AssistantRelationships = {
	.tasks = @"tasks",
};






@implementation AssistantID
@end

@implementation _Assistant

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Assistant" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Assistant";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Assistant" inManagedObjectContext:moc_];
}

- (AssistantID*)objectID {
	return (AssistantID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"hourlyRateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"hourlyRate"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic hourlyRate;



- (double)hourlyRateValue {
	NSNumber *result = [self hourlyRate];
	return [result doubleValue];
}


- (void)setHourlyRateValue:(double)value_ {
	[self setHourlyRate:@(value_)];
}


- (double)primitiveHourlyRateValue {
	NSNumber *result = [self primitiveHourlyRate];
	return [result doubleValue];
}

- (void)setPrimitiveHourlyRateValue:(double)value_ {
	[self setPrimitiveHourlyRate:@(value_)];
}





@dynamic tasks;

	
- (NSMutableSet*)tasksSet {
	[self willAccessValueForKey:@"tasks"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tasks"];
  
	[self didAccessValueForKey:@"tasks"];
	return result;
}
	






@end




