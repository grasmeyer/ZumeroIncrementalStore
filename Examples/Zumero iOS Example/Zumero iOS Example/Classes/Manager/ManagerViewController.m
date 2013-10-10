#import "ManagerViewController.h"

@implementation ManagerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *duplicateButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Duplicate" style:UIBarButtonItemStyleBordered target:self action:@selector(duplicate)];
    self.navigationItem.rightBarButtonItem = duplicateButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"%@", self.manager);
    self.managerNameLabel.text = self.manager.name;
    if ([self.manager.title length] > 0) {
        self.managerTitleLabel.text = self.manager.title;
    } else {
        self.managerTitleLabel.text = @"None";
    }
}

- (void)duplicate
{
    
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([[segue identifier] isEqualToString:@"showTasks"]) {
//        [[segue destinationViewController] setManagedObjectContext:self.manager.managedObjectContext];
//    }
//}

@end
