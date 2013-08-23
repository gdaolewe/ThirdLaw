//
//  TVTropesViewController.m
//  TVTropes
//
//  Created by George Daole-Wellman on 10/28/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "PageViewController.h"
#import "IndexData.h"
#import "FileLoader.h"
#import "HistoryItem.h"
#import "Bookmark.h"
#import "Page.h"
#import "SavedPagesController.h"
#import "SearchViewController.h"
#import "ExternalWebViewController.h"
#import <dispatch/dispatch.h>
#import "Reachability.h"

NSString *const RANDOM_URL;

@interface PageViewController () <NSURLConnectionDataDelegate,UIWebViewDelegate, SavedPagesDelegate, SearchViewDelegate, UIActionSheetDelegate>
-(void) loadURLFromString:(NSString *)urlString;
@property (strong, nonatomic) IBOutlet UIButton *fullscreenOffButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *backForwardCancelButton;


@end

@implementation PageViewController

NSString *const RANDOM_URL = @"http://tvtropes.org/pmwiki/randomitem.php";

@synthesize webView = _webView;
@synthesize fullscreenOffButton = _fullscreenOffButton;
@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;

@synthesize url = _url;
NSString* _script;
bool _backForwardButtonsShowing;
bool _jsInjected;
bool _finishedLoading;
bool _loadingSavedPage;
bool _shouldSaveHistory;
bool _historySaved;

bool _isFullScreen;

dispatch_queue_t backgroundQueue;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
    self.navigationController.toolbarHidden = NO;
    _isFullScreen = NO;
    _backForwardButtonsShowing = NO;
    self.fullscreenOffButton.hidden = YES;
    _script = [FileLoader getScript];
    [HistoryItem setHistoryIndex:0];
    _loadingSavedPage = NO;
    _shouldSaveHistory = YES;
    _historySaved = NO;
    if ([self.url isEqualToString:RANDOM_URL]) {
        [self loadRandomURL];
    } else if (self.url == nil) {
        _shouldSaveHistory = YES;
        self.url = @"http://tvtropes.org/pmwiki/pmwiki.php/Main/HomePage";
        [self loadPageFromHTML: [FileLoader getHomePage]];
    } else {
        [self loadURLFromString:self.url];
    }
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setActivityIndicator:nil];
    [self setFullscreenOffButton:nil];
    [self setBackButton:nil];
    [self setForwardButton:nil];
    [self setBackForwardCancelButton:nil];
    dispatch_release(backgroundQueue);
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewWillDisappear:(BOOL)animated {
    [self hideBackForwardButtons];
    [super viewWillDisappear:animated];
}

-(void) setPageHidden:(BOOL)hidden {
    self.webView.hidden = hidden;
    if (hidden) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void) reachabilityChanged:(NSNotification*) notification
{
	Reachability* reachability = notification.object;
    
	if(reachability.currentReachabilityStatus == NotReachable)
		NSLog(@"Internet off");
	else
		NSLog(@"Internet on");
}

-(void) loadURLFromString:(NSString *)urlString {
    if ([self checkReachable]) {
        [self setPageHidden:YES];
        _finishedLoading = NO;
        _jsInjected = NO;
        self.url = urlString;
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    }
}
-(void)loadPageFromHTML:(NSString*)html{
    [self setPageHidden:YES];
    //_loadingSavedPage = YES;
	_finishedLoading = NO;
    _jsInjected = NO;
    NSURL* baseURL = [[NSBundle mainBundle] resourceURL];
    [self.webView loadHTMLString:html baseURL:baseURL];
}

-(void) loadRandomURL {
    if ([self checkReachable]) {
        [self setPageHidden:YES];
        backgroundQueue = dispatch_queue_create("com.georgedw.Lampshade.RandomURLConnection", NULL);
        void (^doneBlock)(NSURLResponse*, NSData*) = ^(NSURLResponse *response, NSData *data) {
            self.url = response.URL.absoluteString;
            [self loadPageFromHTML:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
            dispatch_release(backgroundQueue);
        };
        dispatch_async(backgroundQueue, ^(void) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:RANDOM_URL]];
            NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(response, data);
            });
        });
    }
}

-(BOOL) checkReachable {
    Reachability *networkReachability = [Reachability reachabilityWithHostName:@"tvtropes.org"];
    NetworkStatus networkStatus = networkReachability.currentReachabilityStatus;
    if (networkStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No connection to TVTropes.org"
                                                        message:@"Check your internet connection or browse offline"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    return networkStatus != NotReachable;
}

#pragma mark - UIWebViewDelegate
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *url = request.URL.absoluteString;
   
    if ([url hasPrefix:@"command://"]) {    //page is finished loading
        [self.webView stringByEvaluatingJavaScriptFromString:@"$('iframe').remove();"];
        NSLog(@"%@", [self.webView stringByEvaluatingJavaScriptFromString:@"url"]);
        [self setPageHidden:NO];
        self.title = [request.URL.query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self addToHistory];
		_finishedLoading = YES;
        NSLog(@"command done");
        return NO;
    }
    else if ([request.URL.host isEqualToString:@"tvtropes.org"]) {
        self.url = url;
        [self setPageHidden:YES];
        _jsInjected = NO;
        NSData* htmlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.url]];
        NSString* htmlString = [[NSString alloc] initWithData:htmlData encoding:NSISOLatin1StringEncoding];
        NSURL* baseURL = [[NSBundle mainBundle] resourceURL];
        [webView loadHTMLString:htmlString baseURL:baseURL];
        
        return NO;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSLog(@"\n\n%@", url);
		ExternalWebViewController *webVC = [self.storyboard instantiateViewControllerWithIdentifier:@"External web view"];
		webVC.url = request.URL;
        [self.navigationController pushViewController:webVC animated:YES];
		return NO;
    } else if ([url hasPrefix:@"file://"]) {
		return YES;
	} else {
        return YES;
    }
}
-(void)webViewDidStartLoad:(UIWebView *)webView {
    [self hideBackForwardButtons];
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityIndicator stopAnimating];
}
-(void) webViewDidFinishLoad:(UIWebView *)webView {
    NSString* documentReadyState = [self.webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    NSLog(@"%@ %@", documentReadyState, _jsInjected? @"YES":@"NO");
    if (([documentReadyState isEqualToString:@"interactive"] || [documentReadyState isEqualToString:@"complete"]) && !_jsInjected) {
        NSString* jQueryString = [NSString stringWithFormat:@"var script = document.createElement('script');script.setAttribute('src','file://%@');document.getElementsByTagName('head')[0].appendChild(script);",[[NSBundle mainBundle] pathForResource:@"jquery" ofType:@"js"]];
        [self.webView stringByEvaluatingJavaScriptFromString:jQueryString];
        NSString* stringForCSS = [NSString stringWithFormat:@"document.getElementsByTagName('link')[1].href='file://%@';",
                                            [FileLoader getCSSPath]];
        [self.webView stringByEvaluatingJavaScriptFromString:stringForCSS];
        [self.webView stringByEvaluatingJavaScriptFromString:_script];
         _jsInjected = YES;
    }
    if (_loadingSavedPage && _jsInjected) {
        _loadingSavedPage = NO;
        [self setPageHidden:NO];
		_finishedLoading = YES;
        [self addToHistory];
    }
}

-(void) addToHistory {
    if (_shouldSaveHistory) {
        NSString *html = [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        [HistoryItem addHistoryItemAsyncWithHTML:html title:self.title uRL:self.url];
        _historySaved = YES;
    } else {
        _shouldSaveHistory = YES;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PageToSearchSegue"]) {
        UINavigationController *nav = (UINavigationController*)segue.destinationViewController;
        ((SearchViewController*)nav.topViewController).delegate = self;
    }
    if ([segue.identifier isEqualToString:@"PageToSavedPagesSegue"]) {
        ((SavedPagesController*)segue.destinationViewController).delegate = self;
    }
}
- (IBAction)home:(UIBarButtonItem *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (IBAction)random:(UIBarButtonItem *)sender {
    [self loadRandomURL];
}

- (IBAction)cancelBackForward:(UIButton *)sender {
    [self hideBackForwardButtons];
}

- (IBAction)tapGesture:(UITapGestureRecognizer *)sender {
    [self hideBackForwardButtons];
}
-(void) hideBackForwardButtons {
    if (_backForwardButtonsShowing) {
        self.webView.alpha = 1;
        self.backButton.hidden = YES;
        self.forwardButton.hidden = YES;
        self.backForwardCancelButton.hidden = YES;
    }
}
- (IBAction)rightSwipeGesture:(UISwipeGestureRecognizer *)sender {
    NSArray* history = [HistoryItem history];
    if ([HistoryItem historyIndex] < history.count-1) {
        self.webView.alpha = 0.5;
        self.forwardButton.hidden = YES;
        self.backButton.hidden = NO;
        self.backForwardCancelButton.hidden = NO;
        _backForwardButtonsShowing = YES;
    }
}
- (IBAction)leftSwipeGesture:(UISwipeGestureRecognizer *)sender {
    if ([HistoryItem historyIndex] > 0) {
        self.webView.alpha = 0.5;
        self.backButton.hidden = YES;
        self.forwardButton.hidden = NO;
        self.backForwardCancelButton.hidden = NO;
        _backForwardButtonsShowing = YES;
    }
}

- (IBAction)back:(UIButton *)sender {
    NSArray* history = [HistoryItem history];
    if ([HistoryItem historyIndex] < history.count-1) {
        [HistoryItem setHistoryIndex:[HistoryItem historyIndex]+1];
        HistoryItem* previous = [history objectAtIndex:[HistoryItem historyIndex]];
        self.url = previous.url;
        self.title = previous.title;
        _shouldSaveHistory = NO;
        _loadingSavedPage = YES;
        [self loadPageFromHTML:previous.html];
    }
}
- (IBAction)forward:(UIButton *)sender {
    if ([HistoryItem historyIndex] > 0) {
        NSArray* history = [HistoryItem history];
        [HistoryItem setHistoryIndex:[HistoryItem historyIndex]-1];
        HistoryItem* next = [history objectAtIndex:[HistoryItem historyIndex]];
        self.url = next.url;
        self.title = next.title;
        _shouldSaveHistory = NO;
        _loadingSavedPage = YES;
        [self loadPageFromHTML:next.html];
    }
}

#pragma mark - SavedPagesDelegate
-(void) savedPageController:(id)controller didSelectSavedPage:(id<GenericSavedPage>)page {
    [controller dismissViewControllerAnimated:YES completion:nil];
    _loadingSavedPage = YES;
    self.url = page.url;
    self.title = page.title;
    if ([page isKindOfClass:HistoryItem.class])
        _shouldSaveHistory = NO;
    _loadingSavedPage = YES;
    [self loadPageFromHTML:page.html];
}
-(void)savedPageController:(id)controller didSelectBookmarkWithURL:(NSString *)url {
    [controller dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"bookmark with url @%@", url);
    [self loadURLFromString:url];
}

#pragma mark - SearchViewDelegate
-(void) searchViewController:(id)controller didSelectSearchResult:(NSString *)result {
    NSLog(@"select search result");
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self loadURLFromString:result];
}

#define BOOKMARK_BUTTON 0
#define SAVE_BUTTON 1
#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case BOOKMARK_BUTTON:
            if ([self.url isEqualToString:RANDOM_URL])
                self.url = self.webView.request.mainDocumentURL.absoluteString;
            [Bookmark saveBookmarkAsyncWithURL:self.url title:self.title];
            NSLog(@"saved bookmark with title %@ and url %@", self.title, self.url);
            break;
        case SAVE_BUTTON:
        {
            NSString *html = [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
            [Page savePageAsyncWithHTML:html title:self.title andURL:self.url];
        }
            break;
        default:
            NSLog(@"Cancelled");
            break;
    }
}

- (IBAction)saveActions:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Bookmark", @"Save for offline reading", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)toggleFullscreen:(UIBarButtonItem *)sender {
    if (_isFullScreen) {
        _isFullScreen = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.fullscreenOffButton.hidden = YES;
    } else {
        _isFullScreen = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        self.fullscreenOffButton.hidden = NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
