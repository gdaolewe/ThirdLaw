//
//  SearchResultData.h
//  ThirdLaw
//
//  Created by George Daole-Wellman on 8/28/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchResultData : NSObject

#define BASE_SEARCH_URL @"https://www.google.com/search?q="
#define BASE_SITE_QUERY @"+site:tvtropes.org"

#define MEDIA_NAMESPACES @[@"Advertising", @"ARG", @"Animation", @"Anime", @"AudioPlay", @"Blog", @"Blog", @"Bollywood", @"ComicBook", @"ComicStrip", @"Creator", @"Fanfic", @"Film", @"Franchise", @"LetsPlay", @"LightNovel", @"Literature", @"Machinima", @"Magazine", @"Manga", @"Manhua", @"Manhwa", @"Music", @"Pinball", @"Podcast", @"Radio", @"Ride", @"Roleplay", @"Series", @"TabletopGame", @"Theatre", @"Toys", @"VideoGame", @"VisualNovel", @"WebAnimation", @"Webcomic", @"Website", @"WebOriginal", @"WebVideo", @"WesternAnimation", @"Wiki", @"Wrestling"]

#define SUBPAGE_NAMESPACES @[@"Analysis", @"Characters", @"FanficRecs", @"FanWorks", @"Fridge", @"Haiku", @"Headscratchers", @"ImageLinks", @"Laconic", @"PlayingWith", @"Quotes", @"Recap", @"Synopsis", @"Timeline", @"Trivia", @"WMG", @"YMMV"]

#define MOMENTS_NAMESPACES @[@"Awesome", @"Funny", @"Heartwarming", @"NightmareFuel", @"Tearjerker"]

+(NSString*)siteQueryForNamespaceDictionaries:(NSDictionary*)firstDictionary, ...
	NS_REQUIRES_NIL_TERMINATION;

+(NSArray*)parseData:(NSData*)data;

@end
