#import "TaskViewController.h"
#import "ModelController.h"

@implementation TaskViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *duplicateButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Duplicate" style:UIBarButtonItemStyleBordered target:self action:@selector(duplicate)];
    self.navigationItem.rightBarButtonItem = duplicateButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.taskNameLabel.text = self.task.name;
    if ([self.task.manager.name length] > 0) {
        self.managerNameLabel.text = self.task.manager.name;
    } else {
        self.managerNameLabel.text = @"None";
    }
    self.numberOfAssistantsLabel.text = [NSString stringWithFormat:@"%d", [self.task.assistants count]];
}

- (void)duplicate
{
    Task *newTask = [self.task duplicateWithParent:self.task.project];
    newTask.name = @"Duplicated Task";
    [self.task.managedObjectContext saveAndSync];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if ([[segue identifier] isEqualToString:@"showTasks"]) {
//        [[segue destinationViewController] setManagedObjectContext:self.managedObjectContext];
//    }
}

@end
