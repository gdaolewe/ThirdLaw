//
//  Bookmark.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "Bookmark.h"
#import "LampshadeAppDelegate.h"


@implementation Bookmark

@dynamic url;
@dynamic title;

NSArray *_bookmarksCached;

+(void) saveBookmarkURL:(NSString*)url withTitle:(NSString*)title {
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Bookmark *bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    bookmark.url = url;
    bookmark.title = title;
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Error saving bookmark to Core Data: %@", error.localizedDescription);
    } else {
        _bookmarksCached = [self fetchBookMarks];
    }
}
+(void) deleteBookmark:(Bookmark*)bookmark {
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    [context deleteObject:bookmark];
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Error deleting bookmark from Core Data: %@", error.localizedDescription);
    } else {
        _bookmarksCached = [self fetchBookMarks];
    }
}
+(NSArray*) fetchBookMarks {
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:context];
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (results == nil) {
        NSLog(@"Error fetching bookmarks from Core Data");
    }
    return results;
}
+(NSArray*) bookmarks {
    if (_bookmarksCached == nil) {
        _bookmarksCached = [self fetchBookMarks];
    }
    return _bookmarksCached;
        
}


@end
