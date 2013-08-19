//
//  PageData.h
//  Lampshade
//
//  Created by George Daole-Wellman on 1/17/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTTAttributedLabel.h"

@interface PageData : NSObject

+(PageData*)sharedPageDataWithURL:(NSURL*)url;


//-(void) loadHTMLFromURL:(NSURL*)url;

-(NSURL*) pageImageURL;

-(NSString*) pageTitle;

-(TTTAttributedLabel*) pageImageCaptionForLabel:(TTTAttributedLabel*)labe;

//-(NSString*) pageQuote;

-(TTTAttributedLabel*) pageQuoteForLabel:(TTTAttributedLabel*)label;

-(TTTAttributedLabel*) pageLedeForLabel:(TTTAttributedLabel*)label;

@end
