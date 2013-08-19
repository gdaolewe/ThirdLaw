//
//  Bookmark.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Bookmark : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;

+(void) saveBookmarkURL:(NSString*)url withTitle:(NSString*)title;
+(void) deleteBookmark:(Bookmark*)bookmark;
+(NSArray*) bookmarks;

@end
