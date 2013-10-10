#import "ModelController.h"

@interface AppDelegate : UIApplication <UIApplicationDelegate, UIActionSheetDelegate>

extern NSString * const ZumeroIncrementalStoreSyncDidComplete;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) ModelController *modelController;

- (void)resetIdleTimer:(NSTimeInterval)seconds;
- (void)syncAfterDelay:(NSTimeInterval)seconds;

@end
