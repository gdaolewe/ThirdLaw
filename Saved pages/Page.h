//
//  Page.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/26/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GenericSavedPage.h"

#define PAGES_NOTIFICATION_NAME @"com.georgedw.lampshade.pagesupdated"

@interface Page : NSManagedObject <GenericSavedPage>

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * htmlPath;

+(void) savePageAsyncWithHTML:(NSString*)html title:(NSString*)title andURL:(NSString*)url;
+(void) deletePagesAsync:(NSArray*)pages;
+(void) fetchPagesAsync;
+(NSArray*) pages;
+(void) clearCache;

-(NSString*) dateString;

@end
