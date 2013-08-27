//
//  Page.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/26/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "Page.h"
#import "LampshadeAppDelegate.h"


@implementation Page

@dynamic date;
@dynamic title;
@dynamic url;
@dynamic htmlPath;

dispatch_queue_t queue;

NSArray *_pagesCached;

- (NSString*) generatePath
{
	NSTimeInterval timeIntervalSeconds = [NSDate timeIntervalSinceReferenceDate];
	unsigned long long nanoseconds = (unsigned long long) floor(timeIntervalSeconds * 1000000);
	
	return [NSString stringWithFormat:@"SavedPages/%qu.html", nanoseconds];
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
	NSString* html = [NSString stringWithContentsOfFile:[self fullHTMLPath] encoding:NSASCIIStringEncoding error:&error];
	if (error) {
		NSLog(@"Error retrieving page html file from disk: %@", error);
		return nil;
	}
	return html;
}


+(void)savePageAsyncWithHTML:(NSString*)html title:(NSString*)title andURL:(NSString*)url {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.pages", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
        Page *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page" inManagedObjectContext:context];
        page.html = html;
        page.title = title;
        page.url = url;
        NSDate *date = [NSDate date];
        page.date = date;
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error saving page to Core Data: %@", error.localizedDescription);
        } else {
            _pagesCached = [self fetchPages];
            [[NSNotificationCenter defaultCenter] postNotificationName:PAGES_NOTIFICATION_NAME object:self];
        }
    });
}

+(void) deletePagesAsync:(NSArray*)pages {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.pages", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
		NSFileManager *fileMgr = [NSFileManager defaultManager];
		NSError *error;
        for (Page* page in pages) {
			[fileMgr removeItemAtPath:[page fullHTMLPath] error:&error];
			if (error)
				NSLog(@"Error deleting page's HTML from disk");
            [context deleteObject:page];
		}
        error = nil;
        if (![context save:&error]) {
            NSLog(@"Error deleting page from Core Data: %@", error.localizedDescription);
        } else {
            _pagesCached = [self fetchPages];
            [[NSNotificationCenter defaultCenter] postNotificationName:PAGES_NOTIFICATION_NAME object:self];
        }
    });
}

+(NSArray*) fetchPages {
    NSManagedObjectContext *context = ((LampshadeAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Page" inManagedObjectContext:context];
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (results == nil) {
        NSLog(@"Error fetching pages from Core Data");
    }
    return results;
}

+(void) fetchPagesAsync {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.pages", NULL);
    dispatch_async(queue, ^{
        _pagesCached = [self fetchPages];
        [[NSNotificationCenter defaultCenter] postNotificationName:PAGES_NOTIFICATION_NAME object:self];
    });
}

+(NSArray*) pages {
    if (_pagesCached == nil)
        _pagesCached = [self fetchPages];
    return _pagesCached;
}
+(void) clearCache {
    if (!queue)
        queue = dispatch_queue_create("com.georgedw.lampshade.pages", NULL);
    dispatch_async(queue, ^{
        _pagesCached = nil;
    });
}

-(NSString*) dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM/dd/yyyy";
    return [formatter stringFromDate:self.date];
    
}

@end
