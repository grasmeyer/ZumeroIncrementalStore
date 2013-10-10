#import "Model.h"

@interface TasksViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic) Project *project;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
