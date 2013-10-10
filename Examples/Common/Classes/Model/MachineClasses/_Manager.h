// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Manager.h instead.

#import <CoreData/CoreData.h>
#import "Person.h"



extern const struct ManagerAttributes {
	__unsafe_unretained NSString *title;
} ManagerAttributes;



extern const struct ManagerRelationships {
	__unsafe_unretained NSString *tasks;
} ManagerRelationships;






@class Task;




@interface ManagerID : PersonID {}
@end

@interface _Manager : Person {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ManagerID*)objectID;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;





@end


@interface _Manager (TasksCoreDataGeneratedAccessors)
- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(Task*)value_;
- (void)removeTasksObject:(Task*)value_;
@end


@interface _Manager (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;





- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;


@end
