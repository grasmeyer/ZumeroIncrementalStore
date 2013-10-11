#import "ZumeroExampleIncrementalStore.h"

@implementation ZumeroExampleIncrementalStore

+ (void)initialize
{
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type
{
    return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model
{
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ZumeroExample" withExtension:@"momd"]];
}

+ (NSString *)databaseFilename
{
	return @"zedata";
}

+ (NSString *)databaseRemoteFilename
{
	return @"zeremotedata";
    
}

+ (NSString *)server
{
    // Zumero server
    // You will receive a custom Zumero Server URL when you sign up for your free Zumero account
//	return @"YOUR_ZUMERO_SERVER_URL";
    
    // Local server without virtual host
	return @"http://localhost:8080";
    
    // Get this app to use the following 2 local server URLs:
    // http://clickontyler.com/virtualhostx/
    
    // Local server with virtual host
    // You can set this up in VirtualHostX
//	return @"http://zumero.dev:8080";
    
    // Local server with virtual host over local network
    // You can get this URL from the "Local Domain Name" field in the Advanced Options section of the VirtualHostX window
//	return @"http://zumero.dev.10.0.1.8.xip.io:8080";
}

+ (NSString *)username
{
	return @"user";
}

+ (NSString *)password
{
	return @"userpass";
}

+ (NSDictionary *)scheme
{
	return @{ @"dbfile": @"zauth", @"scheme_type": @"internal" };
}

@end
