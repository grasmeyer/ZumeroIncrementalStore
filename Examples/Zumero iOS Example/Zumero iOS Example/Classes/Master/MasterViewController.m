#import "MasterViewController.h"
#import "ProjectsViewController.h"
#import "AppDelegate.h"

@implementation MasterViewController

- (void)awakeFromNib
{
    UIBarButtonItem *syncButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStyleBordered target:self action:@selector(sync:)];
    self.toolbarItems = @[syncButtonItem];

    [super awakeFromNib];
}

- (void)sync:(id)sender
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate syncAfterDelay:1];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showProjects"] ||
        [[segue identifier] isEqualToString:@"showManagers"] ) {
        [[segue destinationViewController] setManagedObjectContext:self.managedObjectContext];
    }
}

@end
