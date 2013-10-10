// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Task.h instead.

#import <CoreData/CoreData.h>
#import "ModelObject.h"


extern const struct TaskAttributes {
	__unsafe_unretained NSString *dueDate;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *priority;
} TaskAttributes;



extern const struct TaskRelationships {
	__unsafe_unretained NSString *assistants;
	__unsafe_unretained NSString *manager;
	__unsafe_unretained NSString *photo;
	__unsafe_unretained NSString *project;
} TaskRelationships;






@class Assistant;
@class Manager;
@class Photo;
@class Project;








@interface TaskID : NSManagedObjectID {}
@end

@interface _Task : ModelObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (TaskID*)objectID;





@property (nonatomic, strong) NSDate* dueDate;



//- (BOOL)validateDueDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* priority;




@property (atomic) int64_t priorityValue;
- (int64_t)priorityValue;
- (void)setPriorityValue:(int64_t)value_;


//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *assistants;

- (NSMutableSet*)assistantsSet;




@property (nonatomic, strong) Manager *manager;

//- (BOOL)validateManager:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) Photo *photo;

//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) Project *project;

//- (BOOL)validateProject:(id*)value_ error:(NSError**)error_;





@end


@interface _Task (AssistantsCoreDataGeneratedAccessors)
- (void)addAssistants:(NSSet*)value_;
- (void)removeAssistants:(NSSet*)value_;
- (void)addAssistantsObject:(Assistant*)value_;
- (void)removeAssistantsObject:(Assistant*)value_;
@end


@interface _Task (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveDueDate;
- (void)setPrimitiveDueDate:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (int64_t)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(int64_t)value_;





- (NSMutableSet*)primitiveAssistants;
- (void)setPrimitiveAssistants:(NSMutableSet*)value;



- (Manager*)primitiveManager;
- (void)setPrimitiveManager:(Manager*)value;



- (Photo*)primitivePhoto;
- (void)setPrimitivePhoto:(Photo*)value;



- (Project*)primitiveProject;
- (void)setPrimitiveProject:(Project*)value;


@end
