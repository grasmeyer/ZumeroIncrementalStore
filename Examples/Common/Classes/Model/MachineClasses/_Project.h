// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Project.h instead.

#import <CoreData/CoreData.h>
#import "ModelObject.h"


extern const struct ProjectAttributes {
	__unsafe_unretained NSString *name;
} ProjectAttributes;



extern const struct ProjectRelationships {
	__unsafe_unretained NSString *tasks;
} ProjectRelationships;






@class Task;




@interface ProjectID : NSManagedObjectID {}
@end

@interface _Project : ModelObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ProjectID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;





@end


@interface _Project (TasksCoreDataGeneratedAccessors)
- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(Task*)value_;
- (void)removeTasksObject:(Task*)value_;
@end


@interface _Project (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;


@end
