#import "CoreDataStackTestCase.h"
#import "MockModelController.h"

BOOL const USE_ZUMERO_STORE = YES;

@implementation CoreDataStackTestCase

- (void)setUp
{
    [super setUp];

    NSString *databasePath;
    if (USE_ZUMERO_STORE) {
        databasePath = [[[NSFileManager applicationDocumentsDirectory] path] stringByAppendingPathComponent:[MockIncrementalStore databaseFilename]];
    } else {
        databasePath = [[[NSFileManager applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"ZumeroTest.sqlite"];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:databasePath error:nil];

    self.modelController = [[MockModelController alloc] initWithSampleData:YES useZumeroStore:YES];
}

- (void)tearDown
{
    [super tearDown];
    
    self.modelController = nil;
}

- (void)testModelControllerExists
{
    XCTAssertNotNil(self.modelController, @"self.modelController is nil");
}

@end
