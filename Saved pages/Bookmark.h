//
//  Bookmark.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define BOOKMARKS_NOTIFICATION_NAME @"com.georgedw.lampshade.bookmarksupdated"

@interface Bookmark : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;

+(void) saveBookmarkAsyncWithURL:(NSString*)url title:(NSString*)title;
+(void) deleteBookmarksAsync:(NSArray*)bookmarks;
+(void) fetchBookmarksAsync;
+(NSArray*) bookmarks;
+(void) clearCache;

@end
