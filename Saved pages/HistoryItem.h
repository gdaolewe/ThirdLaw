//
//  HistoryItem.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GenericSavedPage.h"

#define HISTORY_NOTIFICATION_NAME @"com.georgedw.lampshade.historyupdated"

@interface HistoryItem : NSManagedObject <GenericSavedPage>

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * date;

+(int) historyIndex;
+(void) setHistoryIndex:(int)index;
+(void) addHistoryItemAsyncWithHTML:(NSString*)html title:(NSString*)title andURL:(NSString*)url;
+(void) fetchHistoryAsync;
+(NSArray*) history;
+(void) clearHistoryAsync;
+(void) clearHistoryNewerThanIndex:(int)index;
+(void) clearCache;

-(NSString*) dateString;

@end
