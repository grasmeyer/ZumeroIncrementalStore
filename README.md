# ZumeroIncrementalStore

ZumeroIncrementalStore is an [`NSIncrementalStore`](https://developer.apple.com/library/ios/DOCUMENTATION/CoreData/Reference/NSIncrementalStore_Class/Reference/NSIncrementalStore.html) subclass that lets you use Core Data with the [Zumero SDK](http://zumero.com) to sync data between iOS and Mac apps. Zumero is a "replicate and sync" technology based on SQLite that allows apps to be fully functional offline and sync in the background when they're online. 

### What does that mean?

It means that you can add syncing to your Core Data app by swapping out Apple's NSPersistentStore with ZumeroIncrementalStore, and as far as the app knows, it's just using Core Data with a local data file. Then whenever you want your app to sync, you call a sync method in the Zumero iOS SDK, and sync happens in the background. 

Here's a top-level overview of how it works:

<p align="center" >
  <img src="/Images/Overview.png">
</p>

The next figure shows how ZumeroIncrementalStore fits into the Core Data stack:

<p align="center" >
  <img src="/Images/ZumeroIncrementalStore.png">
</p>

## A Comparison with Other Syncing Technologies

You can find a blog post at grasmeyer.com that shows a [comparison of the most popular syncing technologies](http://grasmeyer.com/blog/2013/10/8/a-comparison-of-syncing-technologies).

## Advantages of ZumeroIncrementalStore

* You don't have to make any changes to your Core Data model, like adding extra attributes to your entities or subclassing a custom model object base class. 
* You can sync data between multiple users.
* You can sync data with non-Apple platforms such as web apps and Android apps.
* It supports versioning and migrations.
* Each user's data is isolated in their own data file, so they can migrate to the latest version independently of other users, and they can backup and restore their data independently of other users.

## Usage

Normally, when you initialize the Core Data stack for an app, you add a persistent store to your persistent store coordinator with the following line of code:

```objective-c
[_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                          configuration:nil
                                                    URL:storeURL
                                                options:options
                                                  error:&error];
```

To use ZumeroIncrementalStore instead, just replace that line of code with the following line:

```objective-c
[_persistentStoreCoordinator addPersistentStoreWithType:[ZumeroExampleIncrementalStore type]
                                          configuration:nil
                                                    URL:nil
                                                options:options
                                                  error:&error];
```

In this case, `ZumeroExampleIncrementalStore` is the name of your custom subclass of ZumeroIncrementalStore.

Now you can just use Core Data as you normally would. Then when you want your app to sync, just call the following method:

```objective-c
[incrementalStore syncWithCompletionBlock:completionBlock]
```

In this case, `incrementalStore` is the instance of `ZumeroExampleIncrementalStore` and `completionBlock` is a completion block that you can define. You will typically use this completion block to send an `NSNotification` to your user interface so that it can be updated with new data from the sync.

That's all there is to it!

## Alpha Status

ZumeroIncrementalStore is currently an alpha release, and it hasn't been used in any production apps yet. Feedback and contributions from the community are welcome.

## Requirements

ZumeroIncrementalStore requires Xcode 5, iOS 7, and Mac OS X 10.9.

## Getting Started

Take a look at the Zumero iOS Example in the Examples directory. The example app uses several different types of entities, attributes, and relationships to demonstrate and test various aspects of ZumeroIncrementalStore.

## Installation

1. Create a new project in Xcode. Don't check the Core Data checkbox.
2. Add the following line to your `Prefix.pch` file:

        #import <CoreData/CoreData.h>
         
3. Drag the ZumeroIncrementalStore folder into your Xcode project. This folder should contain `ZumeroIncrementalStore.h` and `ZumeroIncrementalStore.m`. Or you can use CocoaPods, as described below.
4. Drag `Zumero.framework` into the Frameworks folder
5. Click on the Target in the sidebar on the left. Click the General Tab. Add the following frameworks:

        CFNetwork.framework
        libsqlite3.dylib
        libz.dylib
        
6. Add a property to your `AppDelegate.h` file for the modelController:

        @property (nonatomic) ModelController *modelController;
        
7. Initialize the `modelController` in the `application:didFinishLaunchingWithOptions:` method of your `AppDelegate.m` file:

        self.modelController = [[ModelController alloc] init];
        
8. Set up a free account at [zumero.com](http://www.zumero.com).
9. Create your own custom subclass of ZumeroIncrementalStore. See the section below for details.
10. Set up your Access Control List. See the section below for details.

### Installation with CocoaPods

You can also use [CocoaPods](http://cocoapods.org) to install ZumeroIncrementalStore.

#### Podfile

```ruby
platform :ios, '7.0'
pod "ZumeroIncrementalStore", "~> 0.1.0"
```

### Mogenerator (optional)

If you want to use mogenerator, set up a Run Script via the following steps. 

1. Select the Target in the sidebar on the left. 
2. Select the Build Phases tab. 
3. Choose "Add Build Phase"->"Add Run Script Build Phase" from the Editor menu. 
4. Drag the Run Script to the second position in the list, just below Target Dependencies. 
5. Paste the following script into the black text field. Then you can change the values for the variables in the script.

```bash
MODEL_DIR="$PROJECT_DIR/../Common/Classes/Model"
DATA_MODEL_FILE="$MODEL_DIR/ZumeroExample.xcdatamodeld/ZumeroExample.xcdatamodel"
MACHINE_SOURCE_DIR="$MODEL_DIR/MachineClasses"
HUMAN_SOURCE_DIR="$MODEL_DIR/HumanClasses"
AGGREGATE_HEADER="$MACHINE_SOURCE_DIR/Model.h"
BASE_CLASS="ModelObject"
TEMPLATES_DIR="$PROJECT_DIR/../../mogenerator/Templates"
../../mogenerator/mogenerator --template-var arc=true --includeh "$AGGREGATE_HEADER" --template-path "$TEMPLATES_DIR" --base-class "$BASE_CLASS" -m "$DATA_MODEL_FILE" -M "$MACHINE_SOURCE_DIR" -H "$HUMAN_SOURCE_DIR"
```

Note that ZumeroIncrementalStore doesn't require you to use a base class for your model objects. However, a base class is often useful for adding methods that apply to all of your model objects, so we used it in the example app to show how it's done.

If you don't already have mogenerator installed, you can get it here:
[https://github.com/rentzsch/mogenerator](https://github.com/rentzsch/mogenerator)

After you download mogenerator, open `mogenerator.xcodeproj`, compile it, and drag the mogenerator executable file to `~/bin`. Then you can use the absolute path to `~/bin/mogenerator` in your Run Script instead of the relative path shown above.

## How to Subclass ZumeroIncrementalStore

You should create a new custom subclass of ZumeroIncrementalStore that overrides some of the methods for the server name, username and password, filenames, etc.

Here's an example of the `ZumeroExampleIncrementalStore.m` file from the Zumero iOS Example in the Examples directory:

```objective-c
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
	return @{ @"dbfile": @"ztauth", @"scheme_type": @"internal" };
}

@end
```

## How to Set Up a Local Zumero Server

1. Download the Zumero Development Server after signing up for a Zumero account at [http://zumero.com/dev-center/](http://zumero.com/dev-center/).
2. Open a new Terminal window and cd to the `zumero_dev_server` directory.
3. Launch the local server by typing `bin/zumero`.
4. Open a new terminal window and cd to the `Examples/Access Control List Setup` directory in this repository. 
5. Open the `local_setup.sql` file and change YOUR_PASSWORD to your own password.
6. Initialize the local Access Control List by typing `sqlite3 :memory: -init local_setup.sql`.

## Known Issues

* The Zumero iOS SDK has a bug related to CFNetworking that can cause the sync to hang in iOS 7. Zumero is currently working with Apple to resolve this issue. 
* As a result, the `SYNC_ENABLED` flag has been set to NO at the top of `AppDelegate.m` for now.
* The Zumero Mac SDK framework hasn't been released yet, so the Zumero Mac Example is just a placeholder for now.
* There is a bug in Xcode 5 that causes the labels to be hidden in some of the UITableViewCells within the Storyboard.

## Next Steps

* Add more unit tests
* Add progressive migration as explained in Marcus Zarra's excellent [Core Data book](http://pragprog.com/book/mzcd2/core-data)
* Add more documentation
* Add support for external blobs

## References

Unfortunately, NSIncrementalStore isn't very well documented. Here are some references if you want to get more info about it.

Apple's Incremental Store Programming Guide:

* https://developer.apple.com/library/ios/documentation/DataManagement/Conceptual/IncrementalStorePG/ImplementationStrategy/ImplementationStrategy.html

Here are a few good blog posts about NSIncrementalStore:

* http://sealedabstract.com/code/nsincrementalstore-the-future-of-web-services-in-ios-mac-os-x/
* http://nshipster.com/nsincrementalstore/
* http://chris.eidhof.nl/post/17826914256/accessing-an-api-using-coredatas-nsincrementalstore

Here are some examples of how others are using NSIncrementalStore:

* https://github.com/AFNetworking/AFIncrementalStore
* https://github.com/project-imas/encrypted-core-data
* http://stackmob.github.io/stackmob-ios-sdk/Classes/SMIncrementalStore.html
* http://www.stoeger-it.de/en/secureincrementalstore/
* https://github.com/chbeer/CBCouchbaseIncrementalStore
* https://groups.google.com/forum/#!topic/mobile-couchbase/3BQHsGz_2A0

## Contact

[Joel Grasmeyer](http://github.com/grasmeyer) ([@grasmeyer](https://twitter.com/grasmeyer))

## License

ZumeroIncrementalStore is available under the MIT license. See the LICENSE.txt file for more info.
