#import "AppDelegate.h"
#import "MasterViewController.h"
#import "NSFileManager+Helpers.h"
#import <AudioToolbox/AudioToolbox.h>

// All times are in seconds
#define kIdleTimeAfterLaunch 5
#define kIdleTimeAfterTouchEvent 5
// The sync interval was changed to 6 seconds for testing purposes, but it should be at least a minute for a production app
//#define kSyncIntervalAfterSuccessfulSync 60
#define kSyncIntervalAfterSuccessfulSync 6
#define kSyncIntervalAfterFailedSync 300

BOOL const DELETE_DATABASE_AT_LAUNCH = NO;
BOOL const USE_ZUMERO_STORE = YES;
// Sync has been disabled for now, since there is an iOS 7-related CFNetworking bug in the Zumero SDK. It should be fixed soon.
BOOL const SYNC_ENABLED = NO;

NSString * const ZumeroIncrementalStoreSyncDidComplete = @"ZumeroIncrementalStoreSyncDidComplete";

@interface AppDelegate() {
    SystemSoundID soundID;
}

@property (nonatomic) NSTimer *idleTimer;
@property (nonatomic) BOOL wantToSync;
@property (nonatomic) NSDate *nextSync;

@end


@implementation AppDelegate

- (void)dealloc
{
    AudioServicesDisposeSystemSoundID(soundID);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create the sound ID
    NSString* path = [[NSBundle mainBundle] pathForResource:@"Submarine" ofType:@"aiff"];
    NSURL* url = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
    
    NSString *databasePath;
    if (USE_ZUMERO_STORE) {
        databasePath = [[[NSFileManager applicationDocumentsDirectory] path] stringByAppendingPathComponent:[ZumeroExampleIncrementalStore databaseFilename]];
    } else {
        databasePath = [[[NSFileManager applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"ZumeroExample.sqlite"];
    }
    
    if (DELETE_DATABASE_AT_LAUNCH) {
        [[NSFileManager defaultManager] removeItemAtPath:databasePath error:nil];
    }

    // If this is the first launch of the app, or if the database was deleted,
    // ask the user how they want to initialize the data
    BOOL databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:databasePath];
    if (! databaseExists) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Do you want to initialize the database with data from the Zumero server, or start with some sample data?"
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Data from the Server", @"Sample Data", nil];
        [actionSheet showInView:self.window];
    } else {
        [self initializeModelControllerWithSampleData:NO];
    }
    return YES;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self initializeModelControllerWithSampleData:NO];
    } else if (buttonIndex == 1) {
        [self initializeModelControllerWithSampleData:YES];
    }
}

- (void)initializeModelControllerWithSampleData:(BOOL)useSampleData
{
    self.modelController = [[ModelController alloc] initWithSampleData:useSampleData useZumeroStore:USE_ZUMERO_STORE];
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    MasterViewController *controller = (MasterViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.modelController.managedObjectContext;

    // Sync shortly after launch, even if the user doesn't do anything in the app.
    // This will pull any changes from the server, and kick off subsequent syncs at the appropriate sync intervals.
    [self syncAfterDelay:1];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	[self killIdleTimer];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	[self killIdleTimer];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	[self startIdleTimer];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	[self startIdleTimer];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Save changes before the application terminates, but don't bother trying to sync
    [self.modelController.managedObjectContext saveWithoutSyncing];
	[self killIdleTimer];
}

#pragma mark - Sync

- (void)killIdleTimer
{
	self.networkActivityIndicatorVisible = NO;
	
	if (self.idleTimer) {
        [self.idleTimer invalidate];
		self.idleTimer = nil;
    }
}

- (void)startIdleTimer
{
	self.networkActivityIndicatorVisible = NO;
    
	if (! self.idleTimer) {
        [self resetIdleTimer:kIdleTimeAfterLaunch];
    }
}

// we're simulating an idle timer -- waiting for a few seconds with no touch activity
//
- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];
	
    // Only want to reset the timer on a Began touch or an Ended touch, to reduce the number of timer resets.
    NSSet *allTouches = [event allTouches];
    if ([allTouches count] > 0) {
        // allTouches count only ever seems to be 1, so anyObject works here.
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase == UITouchPhaseBegan || phase == UITouchPhaseEnded) {
            [self resetIdleTimer:kIdleTimeAfterTouchEvent];
        }
    }
}

- (void)resetIdleTimer:(NSTimeInterval)seconds
{
//    DLog(@"%f", seconds);
    if (self.idleTimer) {
        [self.idleTimer invalidate];
		self.idleTimer = nil;
    }
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}

// we've found an idle moment. Is it time to sync?
//
- (void)idleTimerExceeded
{
	// Has anyone asked us to sync?
	if (self.wantToSync) {
		NSTimeInterval since = [self.nextSync timeIntervalSinceNow];
        
		// Is it time yet?
		if (since <= 0) {
			self.wantToSync = FALSE;
            
			BOOL ok = FALSE;
            
			// kick off a zumero background sync
			// this class will be the ZumeroDBDelegate, so our syncFail/syncSuccess routines
			// will be called as necessary
            if (SYNC_ENABLED) {
                ok = [self sync];
            } else {
                DLog(@"WARNING: Sync is currently disabled.");
            }
            
			if (ok) {
				self.networkActivityIndicatorVisible = YES;
			} else {
				// the sync call failed; try again later
				[self syncAfterDelay:kSyncIntervalAfterFailedSync];
            }
		} else {
			// nope, check again next idle time
			[self resetIdleTimer:since];
		}
		return;
	}
	[self resetIdleTimer:kIdleTimeAfterTouchEvent];
}

// Note that we want to sync, and how soon.
// If we're already waiting, the nearest time wins.
- (void)syncAfterDelay:(NSTimeInterval)seconds
{
	if (! self.wantToSync) {
		self.nextSync = [NSDate dateWithTimeIntervalSinceNow:seconds];
		self.wantToSync = TRUE;
	} else {
        // If the new sync time is sooner than the existing sync time,
        // then set the next sync time to the new sync time
		NSDate *syncTime = [NSDate dateWithTimeIntervalSinceNow:seconds];
		NSComparisonResult comp = [syncTime compare:self.nextSync];
        if (comp == NSOrderedAscending) {
			self.nextSync = syncTime;
        }
	}
	[self resetIdleTimer:kIdleTimeAfterTouchEvent];
}

- (BOOL)sync
{
    ZumeroIncrementalStore *incrementalStore = (ZumeroIncrementalStore *)self.modelController.store;
    ZumeroSyncCompletionBlock completionBlock = ^(BOOL success, NSError *error) {
        if (success) {
            DLog(@"SYNC COMPLETE");
            AudioServicesPlaySystemSound(soundID);

            // Post a notification for the UI to update
            [[NSNotificationCenter defaultCenter] postNotificationName:ZumeroIncrementalStoreSyncDidComplete object:nil userInfo:nil];
            [self syncAfterDelay:kSyncIntervalAfterSuccessfulSync];
        } else {
            [self syncAfterDelay:kSyncIntervalAfterFailedSync];
        }
        self.networkActivityIndicatorVisible = NO;
    };
    return [incrementalStore syncWithCompletionBlock:completionBlock];
}

@end
