//
//  TVTropesAppDelegate.m
//  TVTropes
//
//  Created by George Daole-Wellman on 10/28/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "LampshadeAppDelegate.h"
#import "IndexData.h"
#import "FileLoader.h"
#import "HistoryItem.h"
#import "Styles.h"
#import "Reachability.h"
#import "UserDefaultsHelper.h"

@implementation LampshadeAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

NSUserDefaults *_defaults;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FileLoader downloadFiles];
    [[IndexData sharedIndexData] loadHTML];
	
	//create history and saved pages documents directories if they don't already exist
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *historyPath = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:@"History"];
	NSString *savedPath = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:@"SavedPages"];
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	NSError * error = nil;
	if (![fileMgr fileExistsAtPath:historyPath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:historyPath
								  withIntermediateDirectories:NO
												   attributes:nil
														error:&error];
		if (error)
			NSLog(@"error creating directory: %@", error);
	}
	if (![fileMgr fileExistsAtPath:savedPath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:savedPath
								  withIntermediateDirectories:NO
												   attributes:nil
														error:&error];
		if (error)
			NSLog(@"error creating directory: %@", error);
	}
	
    NSDictionary *appDefaults = @{
		USER_PREF_EXTERNAL_URL				: @"",
        USER_PREF_HISTORY_INDEX             : [NSNumber numberWithInt:-1],
        USER_PREF_ROTATION_LOCKED			: [NSNumber numberWithBool:NO],
        USER_PREF_ROTATION_ORIENTATION      : [NSNumber numberWithInt:UIInterfaceOrientationPortrait],
        USER_PREF_SAVED_PAGES_STARTING_TAB	: [NSNumber numberWithInt:0],
        USER_PREF_SEARCH_STRING             : @"",
		USER_PREF_START_VIEW				: [NSNumber numberWithInt:UserPrefStartViewPage]
    };
    _defaults = [NSUserDefaults standardUserDefaults];
    [_defaults registerDefaults:appDefaults];
    int historyIndex = [_defaults integerForKey:@"HistoryIndex"];
    [HistoryItem setHistoryIndex:historyIndex];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	UINavigationController *navController = (UINavigationController*)self.window.rootViewController;
	UIViewController *startingController = [[navController viewControllers] objectAtIndex:0];
	//if ([_defaults integerForKey:USER_PREF_START_VIEW] == UserPrefStartViewPage)
		//[startingController performSegueWithIdentifier:@"IndexToPageSegue" sender:startingController];
	UIViewController *pageVC = [startingController.storyboard instantiateViewControllerWithIdentifier:@"Page"];
	[navController pushViewController:pageVC animated:NO];
	//if ([_defaults integerForKey:USER_PREF_START_VIEW] == USerPrefStartViewExternal) {
	//	[pageVC performSegueWithIdentifier:@"Page to external web view" sender:pageVC];
	//}
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    BOOL rotationLocked = [_defaults boolForKey:@"RotationLocked"];
    NSUInteger rotationOrientation = [_defaults integerForKey:@"RotationOrientation"];
    if (rotationLocked) {
        if (rotationOrientation == UIInterfaceOrientationLandscapeLeft || rotationOrientation == UIInterfaceOrientationLandscapeRight)
            return UIInterfaceOrientationMaskLandscape;
        else
            return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
        
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SavedPages" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SavedPages.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
