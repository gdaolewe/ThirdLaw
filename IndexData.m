//
//  CategoryData.m
//  TVTropes
//
//  Created by George Daole-Wellman on 11/10/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "IndexData.h"
#import "TFHpple.h"
#import "Parser.h"
#import "Contributor.h"
#import "FileLoader.h"

@interface IndexData () {
    NSData *_htmlData;
    NSMutableArray *_categoryHTML;
    NSArray *_exampleHTML;
    NSString *_homePageHTML;
}

@end

@implementation IndexData

static IndexData* _singletonIndexData = nil;

+(IndexData *)sharedIndexData {
    @synchronized([IndexData class])
	{
		if (!_singletonIndexData) {
			_singletonIndexData = [[self alloc] init];
        }
		return _singletonIndexData;
	}
    
	return nil;
}

-(int) categoryCount {
    return _categoryHTML.count;
}
-(int) examplesCountForCategoryIndex:(int)categoryIndex {
    return [((TFHppleElement *)[_exampleHTML objectAtIndex:categoryIndex]) children].count;
}

-(void) loadHTML {
    _htmlData = [FileLoader getIndexData];
    TFHpple *parser = [TFHpple hppleWithHTMLData:_htmlData];
    _categoryHTML = [[parser searchWithXPathQuery:@"//div[@id='wikitext']/h2/span"] mutableCopy];
    _exampleHTML = [parser searchWithXPathQuery:@"//div[@id='wikitext']/ul"];
    for (int i=0; i<_categoryHTML.count; i++) {
        TFHppleElement *element = [[_categoryHTML objectAtIndex:i] firstChild];
        NSString *cat;
        if (element.content == nil) {
            cat = [element firstChild].content;
        } else {
            cat = element.content;
        }
        [_categoryHTML replaceObjectAtIndex:i withObject:cat];
    }
}

-(NSString *)categoryNameAtIndex:(int)index {
    return [_categoryHTML objectAtIndex:index];
}

-(NSString *)exampleNameForCategoryIndex:(int)category atIndex:(int) index {
    TFHppleElement *e = [_exampleHTML objectAtIndex:category];
    NSString *content = [[[[e children] objectAtIndex:index] firstChildWithTagName:@"a"] firstChild].content;
    if (content == nil)
       content = [[[e children] objectAtIndex:index] firstChild].content;
    return content;
}

-(NSString *)urlForCategoryIndex:(int)category atIndex:(int)index {
    TFHppleElement *e = [_exampleHTML objectAtIndex:category];
    return [[[[e children] objectAtIndex:index] firstChildWithTagName:@"a"] objectForKey:@"href"];
}

-(NSString*) homePage {
    return _homePageHTML;
}

@end
