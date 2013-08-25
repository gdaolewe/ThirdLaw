//
//  HistoryItem.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "HistoryItem.h"
#import "LampshadeAppDelegate.h"

@implementation HistoryItem

@dynamic title;
@dynamic html;
@dynamic url;
@dynamic date;

NSArray *_historyCached;
NSDateFormatter *_formatter;

static int _historyIndex;
dispatch_queue_t queue;

+(int) historyIndex {
    return _historyIndex;
}

+(void)setHistoryIndex:(int)index {
    _historyIndex = index;
    [[NSUserDefaults standardUserDefaults] setInteger:_historyIndex forKey:@"HistoryIndex"];
}

+(void)addHistoryItemAsyncWithHTML:(NSString *)html title:(NSString *)title andURL:(NSString*)url {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.history", NULL);
    dispatch_async(queue, ^{
        [self clearHistoryNewerThanIndex:[self historyIndex]];
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
        NSError *error = nil;
        NSArray* historyArray = [self history];
        if (historyArray.count > 29) {
            //delete oldest history item,
            HistoryItem *oldest = (HistoryItem*)[historyArray lastObject];
            [context deleteObject:oldest];
        }
        //insert new item,
        HistoryItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"HistoryItem" inManagedObjectContext:context];
        item.html = html;
        item.title = title;
        item.url = url;
        NSDate *date = [NSDate date];
        item.date = date;
        //then save
        if (![context save:&error]) {
            NSLog(@"Error saving history to Core Data: %@", error.localizedDescription);
        } else {
            [self setHistoryIndex:0];
            _historyCached = [self fetchHistory];
            [[NSNotificationCenter defaultCenter] postNotificationName:HISTORY_NOTIFICATION_NAME object:self];
        }

    });
}

+(NSArray*) fetchHistory {
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HistoryItem" inManagedObjectContext:context];
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (results == nil) {
        NSLog(@"Error fetching history from Core Data");
    }
    return results;
}

+(void) fetchHistoryAsync {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.history", NULL);
    dispatch_async(queue, ^{
        _historyCached = [self fetchHistory];
        [[NSNotificationCenter defaultCenter] postNotificationName:HISTORY_NOTIFICATION_NAME object:self];
    });
}

+(NSArray*) history {
    if (_historyCached == nil)
        _historyCached = [self fetchHistory];
    return _historyCached;
}

+(void) clearHistoryAsync {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.history", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
        NSArray *history = [self history];
        for (HistoryItem *item in history) {
            [context deleteObject:item];
        }
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error clearing history from Core Data: %@", error.localizedDescription);
        } else {
            [self setHistoryIndex:0];
            _historyCached = [self fetchHistory];
            [[NSNotificationCenter defaultCenter] postNotificationName:HISTORY_NOTIFICATION_NAME object:self];
        }
    });
}

+(void) clearHistoryNewerThanIndex:(int)index {
    if (index == 0)
        return;
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSArray *history = [self history];
    for (int i=index-1; i>=0; i--) {
        [context deleteObject:[history objectAtIndex:i]];
    }
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Error clearing history from Core Data: %@", error.localizedDescription);
    } else {
        [self setHistoryIndex:0];
        _historyCached = [self fetchHistory];
        [[NSNotificationCenter defaultCenter] postNotificationName:HISTORY_NOTIFICATION_NAME object:self];
    }
}

+(void) clearCache {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.history", NULL);
    dispatch_async(queue, ^{
        _historyCached = nil;
    });
}

-(NSString*) dateString {
    if (_formatter == nil) {
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"MM/dd/yyyy HH:mm";
    }
    return [_formatter stringFromDate:self.date];
}

@end
