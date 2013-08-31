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
#import "NSString+URLEncoding.h"

@interface SearchResultData ()

@end

@implementation SearchResultData

+(NSString*)siteQueryForNamespaceDictionaries:(NSDictionary*)arg1, ... {
	va_list args;
    va_start(args, arg1);
	NSString* siteQuery = @"";
	BOOL usePipeChar = NO;
	for (NSDictionary *arg = arg1; arg != nil; arg = va_arg(args, NSDictionary*)) {
		for (NSString *namespace in [arg allKeys]) {
			if ([[arg objectForKey:namespace] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
				if(usePipeChar)
					siteQuery = [siteQuery stringByAppendingString:@" |"];
				else {
					usePipeChar = YES;
				}
				siteQuery = [siteQuery stringByAppendingFormat:@"%@%@",@" site:tvtropes.org/pmwiki/pmwiki.php/", namespace];
			}
		}
	}
	va_end(args);
	if (siteQuery.length == 0)
		siteQuery = BASE_SITE_QUERY;
	return [siteQuery urlEncode];
}

+(NSArray*)parseData:(NSData*)data {
	NSMutableArray *results = [NSMutableArray array];
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSMutableArray *titles = [NSMutableArray array];
	NSArray *titleElements = [parser searchWithXPathQuery:@"//h3[@class='r']//a"];
	for (TFHppleElement *e in titleElements) {
		NSMutableString *title = [NSMutableString string];
		for (TFHppleElement *c in e.children) {
			if (c.isTextNode && c.content)
				[title appendString:c.content];
			else if (c.text)
				[title appendString:c.text];
		}
		NSLog(@"%@", title);
		[titles addObject:title];
	}
	NSMutableArray *links = [NSMutableArray array];
	NSArray *linkElements = [parser searchWithXPathQuery:@"//h3[@class='r']//a"];
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
		NSLog(@"%@", desc);
		[descriptions addObject:desc];
	}
	if (descElements.count == 0 || linkElements.count == 0) {
		NSArray *	errorElements = [parser searchWithXPathQuery:@"//div[@id='infoDiv']/text()"];
		for (TFHppleElement *e in errorElements)
			NSLog(@"%@", e.content);
	}
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
