#import "Model.h"

@interface ProjectViewController : UITableViewController

@property (nonatomic) Project *project;
@property (strong, nonatomic) IBOutlet UILabel *projectNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberOfTasksLabel;

@end
