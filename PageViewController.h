//
//  TVTropesViewController.h
//  TVTropes
//
//  Created by George Daole-Wellman on 10/28/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenericSavedPage.h"
#import <UIViewController+MMDrawerController.h>
#import "SavedPagesController.h"

extern NSString *const HOME_URL;
extern NSString *const RANDOM_URL;

@interface PageViewController : UIViewController <SavedPagesDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property NSString *url;

/*!
	Loads a TVTropes page from a URL
	@param urlString 
		the URL of the page to load in string form
 */
-(void) loadURLFromString:(NSString *)urlString;

/*!
	Loads a cached TVTropes page from disk
	@param html
		The cached page HTML data represented as NSString
 */
-(void) loadPageFromHTML:(NSString*)html;

/*!
	Loads the TVTropes home page from disk
 */
-(void) loadHomePage;

/*!
	Loads a random TVTropes page from the web
 */
-(void) loadRandomURL;

#pragma mark - SavedPagesDelegate

/*!
	Loads a cached TVTropes page from disk and dismisses any calling modal ViewController
	@param page
		A CoreData representation of the cached page to be loaded
 */
-(void) savedPageController:(id)controller didSelectSavedPage:(id<GenericSavedPage>)page;

/*!
	Loads a TVTropes page from the web and dismisses any calling modal ViewController
	@param url
		the URL of the page to load in string form
 */
-(void)savedPageController:(id)controller didSelectBookmarkWithURL:(NSString *)url;

@end
