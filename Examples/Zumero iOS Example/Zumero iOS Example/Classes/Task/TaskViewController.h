#import "Model.h"

@interface TaskViewController : UITableViewController

@property (nonatomic) Task *task;
@property (strong, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *managerNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberOfAssistantsLabel;

@end
