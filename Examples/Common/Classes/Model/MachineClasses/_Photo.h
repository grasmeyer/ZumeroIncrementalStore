// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Photo.h instead.

#import <CoreData/CoreData.h>
#import "ModelObject.h"


extern const struct PhotoAttributes {
	__unsafe_unretained NSString *data;
	__unsafe_unretained NSString *filename;
} PhotoAttributes;



extern const struct PhotoRelationships {
	__unsafe_unretained NSString *task;
} PhotoRelationships;






@class Task;






@interface PhotoID : NSManagedObjectID {}
@end

@interface _Photo : ModelObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (PhotoID*)objectID;





@property (nonatomic, strong) NSData* data;



//- (BOOL)validateData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* filename;



//- (BOOL)validateFilename:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Task *task;

//- (BOOL)validateTask:(id*)value_ error:(NSError**)error_;





@end



@interface _Photo (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveData;
- (void)setPrimitiveData:(NSData*)value;




- (NSString*)primitiveFilename;
- (void)setPrimitiveFilename:(NSString*)value;





- (Task*)primitiveTask;
- (void)setPrimitiveTask:(Task*)value;


@end
