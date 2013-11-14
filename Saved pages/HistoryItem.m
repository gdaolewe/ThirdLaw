//
//  HistoryItem.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/26/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "HistoryItem.h"
#import "LampshadeAppDelegate.h"

@implementation HistoryItem

@dynamic date;
@dynamic htmlPath;
@dynamic title;
@dynamic url;

NSArray *_historyCached;
NSDateFormatter *_formatter;

static int _historyIndex;
static int _historyCount;
dispatch_queue_t queue;

- (NSString*) generatePath
{
	NSTimeInterval timeIntervalSeconds = [NSDate timeIntervalSinceReferenceDate];
	unsigned long long nanoseconds = (unsigned long long) floor(timeIntervalSeconds * 1000000);
	
	return [NSString stringWithFormat:@"History/%qu.html", nanoseconds];
}

- (NSString*) fullHTMLPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:self.htmlPath];
}

-(void)setHtml:(NSString *)html {
	self.htmlPath = [self generatePath];
	NSError *error;
	NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
	[htmlData writeToFile:[self fullHTMLPath] atomically:YES];
	if (error) {
		NSLog(@"Error saving history item html file to disk: %@", error);
		[[NSFileManager defaultManager] removeItemAtPath:self.htmlPath error:nil];
		self.htmlPath = nil;
	}
}

-(NSString*) html {
	if (!self.htmlPath)
		return nil;
	NSError *error;
	NSString* html = [NSString stringWithContentsOfFile:[self fullHTMLPath] encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		NSLog(@"Error retrieving history html file from disk: %@", error);
		return nil;
	}
	return html;
}

+(void)setHistoryIndex:(int)index {
    _historyIndex = index;
    [[NSUserDefaults standardUserDefaults] setInteger:_historyIndex forKey:@"HistoryIndex"];
}

+(int) historyIndex {
    return _historyIndex;
}

+(int) historyCount {
	return _historyCount;
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
	_historyCount = _historyCached.count;
    return _historyCached;
}

+(void) clearHistoryAsync {
	_historyCount = 0;
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.history", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
		NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray *history = [self history];
		NSError *error;
        for (HistoryItem *item in history) {
			[fileMgr removeItemAtPath:[item fullHTMLPath] error:&error];
			if (error)
				NSLog(@"Error deleting history item's HTML from disk");
            [context deleteObject:item];
        }
        error = nil;
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
	NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *history = [self history];
    for (int i=index-1; i>=0; i--) {
		NSError *error;
		HistoryItem *item = [history objectAtIndex:i];
		[fileMgr removeItemAtPath:[item fullHTMLPath] error:&error];
		if (error)
			NSLog(@"Error clearing history item's html file from disk: %@", error);
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
