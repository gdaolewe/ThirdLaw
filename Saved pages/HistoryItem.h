//
//  HistoryItem.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HistoryItem : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * date;

+(void) addHistoryItemHTML:(NSString*)html withTitle:(NSString*)title andURL:(NSString*)url;
+(NSArray*) history;
+(void) clearHistory;
-(NSString*) dateString;

@end
