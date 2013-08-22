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

+(void)addHistoryItemHTML:(NSString *)html withTitle:(NSString *)title andURL:(NSString*)url {
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
    }
}

+(NSArray*) history {
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

+(void) clearHistory {
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSArray *history = [self history];
    for (HistoryItem *item in history) {
        [context deleteObject:item];
    }
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Error clearing history from Core Data: %@", error.localizedDescription);
    }
}

-(NSString*) dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM/dd/yyyy HH:mm";
    return [formatter stringFromDate:self.date];
}

@end
