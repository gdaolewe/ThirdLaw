//
//  SearchResultData.m
//  ThirdLaw
//
//  Created by George Daole-Wellman on 8/28/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "SearchResultData.h"
#import "TFHpple.h"
#import "Parser.h"

@interface SearchResultData ()

@property NSData *data;

@end

@implementation SearchResultData

@synthesize data = _data;

+(NSArray*)parseData:(NSData*)data {
	NSMutableArray *results = [NSMutableArray array];
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSMutableArray *titles = [NSMutableArray array];
	NSArray *titleElements = [parser searchWithXPathQuery:@"//h3[@class='r']/a"];
	for (TFHppleElement *e in titleElements) {
		NSMutableString *title = [NSMutableString string];
		for (TFHppleElement *c in e.children) {
			if (c.isTextNode && c.content)
				[title appendString:c.content];
			else if (c.text)
				[title appendString:c.text];
		}
		[titles addObject:title];
	}
	NSMutableArray *links = [NSMutableArray array];
	NSArray *linkElements = [parser searchWithXPathQuery:@"//h3[@class='r']/a"];
	for (TFHppleElement *e in linkElements) {
		NSString *link = [e objectForKey:@"href"];
		for (NSString *param in [link componentsSeparatedByString:@"&"]) {
			if ([param hasPrefix:@"/url?q="]) {
				link = [param stringByReplacingOccurrencesOfString:@"/url?q=" withString:@""];
				break;
			}
		}
		NSLog(@"%@", link);
		[links addObject:link];
	}
	NSMutableArray *descriptions = [NSMutableArray array];
	NSArray *descElements = [parser searchWithXPathQuery:@"//span[@class='st']"];
	for (TFHppleElement *e in descElements) {
		NSMutableString *desc = [NSMutableString string];
		for (TFHppleElement *c in e.children) {
			if (c.isTextNode && c.content)
				[desc appendString:c.content];
			else if (c.text)
				[desc appendString:c.text];
		}
		[descriptions addObject:desc];
	}
	NSLog(@"titles count: %d", titles.count);
	NSLog(@"links count: %d", links.count);
	NSLog(@"descriptions count: %d", descriptions.count);
	for (int i=0; i<titles.count; i++) {
		[results addObject:
			@{
				@"title"		: [titles objectAtIndex:i],
				@"link"			: [links objectAtIndex:i],
				@"description"	: [descriptions objectAtIndex:i]
			}
		 ];
	}
	return [results copy];
}

@end
