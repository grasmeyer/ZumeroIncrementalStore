#import "ProjectViewController.h"
#import "TasksViewController.h"
#import "AppDelegate.h"

@implementation ProjectViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *duplicateButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Duplicate" style:UIBarButtonItemStyleBordered target:self action:@selector(duplicate)];
    self.navigationItem.rightBarButtonItem = duplicateButtonItem;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView) name:ZumeroIncrementalStoreSyncDidComplete object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateView];
}

- (void)updateView
{
    DLog(@"UPDATE VIEW");
    [self.project.managedObjectContext refreshObject:self.project mergeChanges:NO];
    
// TODO: Figure out what to do if the project was deleted by another device, and it no longer exists
    
    self.projectNameLabel.text = self.project.name;
    self.numberOfTasksLabel.text = [NSString stringWithFormat:@"%d", [self.project.tasks count]];
}

- (void)duplicate
{
    Project *newProject = [self.project duplicateWithParent:nil];
    newProject.name = @"Duplicated Project";
    [self.project.managedObjectContext saveAndSync];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
     if ([[segue identifier] isEqualToString:@"showTasks"]) {
        [[segue destinationViewController] setManagedObjectContext:self.project.managedObjectContext];
        [[segue destinationViewController] setProject:self.project];
    }
}

@end
