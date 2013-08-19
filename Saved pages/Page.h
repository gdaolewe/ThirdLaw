//
//  Page.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Page : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * date;

+(void) savePageHTML:(NSString*)html withTitle:(NSString*)title andURL:(NSString*)url;
+(void) deletePage:(Page*)page;
+(NSArray*) pages;
-(NSString*) dateString;
@end
