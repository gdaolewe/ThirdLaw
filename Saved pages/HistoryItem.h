//
//  HistoryItem.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/26/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GenericSavedPage.h"

#define HISTORY_NOTIFICATION_NAME @"com.georgedw.lampshade.historyupdated"

@interface HistoryItem : NSManagedObject <GenericSavedPage>

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * htmlPath;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;

+(void)setHistoryIndex:(int)index;
+(int)historyIndex;
+(int)historyCount;
+(void)addHistoryItemAsyncWithHTML:(NSString *)html title:(NSString *)title andURL:(NSString*)url;
+(void) fetchHistoryAsync;
+(NSArray*) history;
+(void) clearHistoryAsync;
+(void) clearCache;

-(NSString*) dateString;

@end
