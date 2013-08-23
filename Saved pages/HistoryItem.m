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

+(int) historyIndex {
    return _historyIndex;
}

+(void)setHistoryIndex:(int)index {
    _historyIndex = index;
    [[NSUserDefaults standardUserDefaults] setInteger:_historyIndex forKey:@"HistoryIndex"];
}

+(void)addHistoryItemAsyncWithHTML:(NSString *)html title:(NSString *)title uRL:(NSString*)url {
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.georgedw.Lampshade.AddHistory", NULL);
    dispatch_async(backgroundQueue, ^{
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

+(NSArray*) history {
    if (_historyCached == nil)
        _historyCached = [self fetchHistory];
    return _historyCached;
}

+(void) clearHistory {
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
    }
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
    }
}

-(NSString*) dateString {
    if (_formatter == nil) {
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"MM/dd/yyyy HH:mm";
    }
    return [_formatter stringFromDate:self.date];
}

@end
