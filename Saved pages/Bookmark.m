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

dispatch_queue_t queue;

NSArray *_bookmarksCached;

+(void) saveBookmarkAsyncWithURL:(NSString*)url title:(NSString*)title {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.bookmarks", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
        Bookmark *bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
        bookmark.url = url;
        bookmark.title = title;
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error saving bookmark to Core Data: %@", error.localizedDescription);
        } else {
            _bookmarksCached = [self fetchBookMarks];
            [[NSNotificationCenter defaultCenter] postNotificationName:BOOKMARKS_NOTIFICATION_NAME object:self];
        }
    });
}
+(void) deleteBookmarksAsync:(NSArray*)bookmarks {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.bookmarks", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
        for (Bookmark* bookmark in bookmarks)
            [context deleteObject:bookmark];
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error deleting bookmark from Core Data: %@", error.localizedDescription);
        } else {
            _bookmarksCached = [self fetchBookMarks];
            [[NSNotificationCenter defaultCenter] postNotificationName:BOOKMARKS_NOTIFICATION_NAME object:self];
        }
    });
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

+(void) fetchBookmarksAsync {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.bookmarks", NULL);
    dispatch_async(queue, ^{
        _bookmarksCached = [self fetchBookMarks];
        [[NSNotificationCenter defaultCenter] postNotificationName:BOOKMARKS_NOTIFICATION_NAME object:self];
    });
}

+(NSArray*) bookmarks {
    if (_bookmarksCached == nil) {
        _bookmarksCached = [self fetchBookMarks];
    }
    return _bookmarksCached;
}

+(void) clearCache {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.bookmarks", NULL);
    dispatch_async(queue, ^{
        _bookmarksCached = nil;
    });

}

@end
