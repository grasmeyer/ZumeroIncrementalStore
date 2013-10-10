// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Assistant.h instead.

#import <CoreData/CoreData.h>
#import "Person.h"



extern const struct AssistantAttributes {
	__unsafe_unretained NSString *hourlyRate;
} AssistantAttributes;



extern const struct AssistantRelationships {
	__unsafe_unretained NSString *tasks;
} AssistantRelationships;






@class Task;




@interface AssistantID : PersonID {}
@end

@interface _Assistant : Person {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (AssistantID*)objectID;





@property (nonatomic, strong) NSNumber* hourlyRate;




@property (atomic) double hourlyRateValue;
- (double)hourlyRateValue;
- (void)setHourlyRateValue:(double)value_;


//- (BOOL)validateHourlyRate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;





@end


@interface _Assistant (TasksCoreDataGeneratedAccessors)
- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(Task*)value_;
- (void)removeTasksObject:(Task*)value_;
@end


@interface _Assistant (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveHourlyRate;
- (void)setPrimitiveHourlyRate:(NSNumber*)value;

- (double)primitiveHourlyRateValue;
- (void)setPrimitiveHourlyRateValue:(double)value_;





- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;


@end
