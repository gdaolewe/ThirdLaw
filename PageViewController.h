//
//  TVTropesViewController.h
//  TVTropes
//
//  Created by George Daole-Wellman on 10/28/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenericSavedPage.h"
#import "SavedPagesController.h"

extern NSString *const RANDOM_URL;

@interface PageViewController : UIViewController <SavedPagesDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property NSString *url;

-(void)loadPageFromHTML:(NSString*)html;
-(void) savedPageController:(id)controller didSelectSavedPage:(id<GenericSavedPage>)page;
-(void)savedPageController:(id)controller didSelectBookmarkWithURL:(NSString *)url;

@end
