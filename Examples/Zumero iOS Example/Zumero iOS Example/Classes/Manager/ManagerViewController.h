#import "Model.h"

@interface ManagerViewController : UITableViewController

@property (nonatomic) Manager *manager;
@property (strong, nonatomic) IBOutlet UILabel *managerNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *managerTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberOfTasksLabel;

@end
