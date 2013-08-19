//
//  PageData.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/17/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "PageData.h"
#import "TFHpple.h"

@interface PageData()

@property NSURL* url;

@end

@implementation PageData

@synthesize url = _url;

PageData* _singletonPageData;
NSData* _htmlData;
TFHpple* _parser;
NSArray* _imageHTML;

NSMutableDictionary* linksDictionary;
NSMutableArray* italicsArray;
NSMutableArray* boldArray;


+(PageData*)sharedPageDataWithURL:(NSURL*)url {
    @synchronized([PageData class])
	{
		if (!_singletonPageData)
			_singletonPageData = [[self alloc] init];
        if (![_singletonPageData.url isEqual:url])
            _singletonPageData.url = url;
        [_singletonPageData loadHTML];
		return _singletonPageData;
	}
    
	return nil;
}

-(void) loadHTML {
    _htmlData = [NSData dataWithContentsOfURL:self.url];
    _parser = [TFHpple hppleWithHTMLData:_htmlData];
}

-(NSURL *)pageImageURL {
        _imageHTML = [_parser searchWithXPathQuery:@"//img[@class='embeddedimage']"];
    return [NSURL URLWithString:[[_imageHTML lastObject] objectForKey:@"src"]];
}

-(NSString*) pageTitle {
    TFHppleElement* titleDiv = [[[_parser searchWithXPathQuery:@"//div[@class='pagetitle']/span"] lastObject] firstChild];
    NSString* theTitle = titleDiv.content;
    return theTitle;
}

-(NSMutableString*) parseNodes:(TFHppleElement*)element {
    NSMutableString* result = [NSMutableString stringWithString:@""];
    
    if (!element.hasChildren) {
        if ([element.tagName isEqualToString:@"text"]) {
            [result appendString:element.content];
            return result;
        }
     }
    
    NSArray* nodes = element.children;
    for (TFHppleElement* e in nodes) {
        
        
        
        if ([e.tagName isEqualToString:@"br"])
            [result appendString:@"\n"];
        
        if ([e.tagName isEqualToString:@"p"] || [e.tagName isEqualToString:@"li"] || [e.tagName isEqualToString:@"ul"])
            [result appendString:@"\n\n"];
        
        if ([[e objectForKey:@"class"] isEqualToString:@"indent"]) {
            [result appendString:@"\n\n"];
        }
        
                
        /*if ([e isTextNode]) {
            NSData* stringData = [e.content dataUsingEncoding:NSASCIIStringEncoding];
            NSString* content = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
            [result appendString:content];
            
            if ([e.tagName isEqualToString:@"a"] && [e objectForKey:@"href"]) {
                [linksDictionary setObject:[e objectForKey:@"href"] forKey:content];
            }
            if ([e.parent.tagName isEqualToString:@"em"] || [e.parent.parent.tagName isEqualToString:@"em"]) {
                [italicsArray addObject:content];
            } else if ([e.parent.tagName isEqualToString:@"strong"]) {
                [boldArray addObject:content];
            }*/
        if (e.text) {
            NSData* stringData = [e.text dataUsingEncoding:NSASCIIStringEncoding];
            NSString* content = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
            //[result appendString:content];
            
            if ([e.tagName isEqualToString:@"a"] && [e objectForKey:@"href"]) {
                [linksDictionary setObject:[e objectForKey:@"href"] forKey:content];
                //NSLog(@"%@", [e objectForKey:@"href"]);
            } else if ([e.tagName isEqualToString:@"em"] || [e.parent.tagName isEqualToString:@"em"]) {
                [italicsArray addObject:content];
            } else if ([e.tagName isEqualToString:@"strong"]) {
                [boldArray addObject:content];
            }
        }
        
        [result appendString:[self parseNodes:e]];

            
    }
    return result;
}


-(TTTAttributedLabel*) pageImageCaptionForLabel:(TTTAttributedLabel*)label {
    
    TFHppleElement* captionDiv = [[_parser searchWithXPathQuery:@"//div[@class='acaptionright']"] lastObject];
    
    linksDictionary = [NSMutableDictionary dictionary];
    italicsArray = [NSMutableArray array];
    boldArray = [NSMutableArray array];
    
    NSMutableString* theCaption = [self parseNodes:captionDiv];
    
    [label setText:theCaption afterInheritingLabelAttributesAndConfiguringWithBlock:attributionBlock];
    
    for (NSString* key in linksDictionary) {
        [label addLinkToURL:[NSURL URLWithString:[linksDictionary objectForKey:key]] withRange:[theCaption rangeOfString:key]];
    }
    label.textAlignment = UITextAlignmentCenter;
    return label;
}




-(TTTAttributedLabel*) pageQuoteForLabel:(TTTAttributedLabel*)label {
    NSArray* parsed = [_parser searchWithXPathQuery:@"//div[@id='wikitext']/div[@class='indent']"];
    
    if (parsed.count < 1) {
        label.hidden = YES;
        return label;
    }
    
    linksDictionary = [NSMutableDictionary dictionary];
    italicsArray = [NSMutableArray array];
    boldArray = [NSMutableArray array];
    
    TFHppleElement* pageQuoteDiv = [parsed objectAtIndex:0];
    
    NSMutableString* theQuote = [self parseNodes:pageQuoteDiv];
    label.dataDetectorTypes = UIDataDetectorTypeLink;
    [label setText:theQuote afterInheritingLabelAttributesAndConfiguringWithBlock:attributionBlock];
    label.lineBreakMode = UILineBreakModeWordWrap;
    for (NSString* key in linksDictionary) {
        [label addLinkToURL:[NSURL URLWithString:[linksDictionary objectForKey:key]] withRange:[theQuote rangeOfString:key]];
    }
    label.hidden = NO;
    [label sizeToFit];
    return label;
}

-(TTTAttributedLabel *)pageLedeForLabel:(TTTAttributedLabel *)label {
    NSArray* parsed = [_parser searchWithXPathQuery:@"//div[@id='wikitext']/node()[preceding::div/@class='indent' and not(preceding-sibling::hr)]"];
    
    //NSLog(@"%@", parsed);
    
    if (parsed.count < 1) {
        label.hidden = YES;
        return label;
    }
    
    linksDictionary = [NSMutableDictionary dictionary];
    italicsArray = [NSMutableArray array];
    boldArray = [NSMutableArray array];
    
    NSMutableString* theLede = [NSMutableString stringWithString:@""];
    
    for (TFHppleElement* e in parsed) {
        NSLog(@"%@", e.tagName);
        [theLede appendString:[self parseNodes:e]];
    }
    
    NSLog(@"%@", theLede);
    
    [label setText:theLede afterInheritingLabelAttributesAndConfiguringWithBlock:attributionBlock];
    
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:(id)[[UIColor blueColor] CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
//	[mutableLinkAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
    label.linkAttributes = mutableLinkAttributes;
    
    for (NSString* key in linksDictionary) {
        [label addLinkToURL:[NSURL URLWithString:[linksDictionary objectForKey:key]] withRange:[theLede rangeOfString:key]];
    }
    
    [label sizeToFit];
    
    
    return label;
}

//block to add attributes to NSMutableAttributedString
NSMutableAttributedString* (^attributionBlock)(NSMutableAttributedString*) = ^(NSMutableAttributedString* mutableAttributedString) {
    UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:12];
    CTFontRef italicsFont = CTFontCreateWithName((__bridge CFStringRef)italicSystemFont.fontName, italicSystemFont.pointSize, NULL);
    UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:12];
    CTFontRef boldFont = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
    
    NSRange currentRange = NSMakeRange(0, mutableAttributedString.string.length-1);
    for (NSString* italicsString in italicsArray) {
        NSRange italicsRange = [mutableAttributedString.string rangeOfString:italicsString options:NSLiteralSearch];
        int newRangeLocation = italicsRange.location + italicsRange.length;
        currentRange = NSMakeRange(newRangeLocation, mutableAttributedString.string.length - newRangeLocation - 1);
        if (italicsFont) {
            [mutableAttributedString addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)italicsFont range:italicsRange];
        }
    }
    
    currentRange = NSMakeRange(0, mutableAttributedString.string.length-1);
    for (NSString* boldString in boldArray) {
        NSRange boldRange = [mutableAttributedString.string rangeOfString:boldString options:NSLiteralSearch range:currentRange];
        int newRangeLocation = boldRange.location + boldRange.length;
        currentRange = NSMakeRange(newRangeLocation, mutableAttributedString.string.length - newRangeLocation - 1);
        if (boldFont) {
            [mutableAttributedString addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)boldFont range:boldRange];
        }
    }
    
    
    return mutableAttributedString;
};


@end
