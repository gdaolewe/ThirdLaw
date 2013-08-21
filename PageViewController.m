//
//  TVTropesViewController.m
//  TVTropes
//
//  Created by George Daole-Wellman on 10/28/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "PageViewController.h"
#import "FileLoader.h"
#import "HistoryItem.h"
#import "HistoryTracker.h"
#import "Bookmark.h"
#import "Page.h"
#import "SavedPagesController.h"
#import "SearchViewController.h"
#import "ExternalWebViewController.h"

@interface PageViewController () <UIWebViewDelegate, SavedPagesDelegate, SearchViewDelegate, UIActionSheetDelegate>
-(void) loadURLFromString:(NSString *)urlString;
@property (strong, nonatomic) IBOutlet UIButton *fullscreenOffButton;
@end

@implementation PageViewController
@synthesize webView = _webView;
@synthesize fullscreenOffButton = _fullscreenOffButton;

@synthesize url = _url;
NSString* _script;
bool _jsInjected;
bool _finishedLoading;
bool _loadingSavedPage;
bool _shouldSaveHistory;
bool _historySaved;

bool _isFullScreen;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
    self.navigationController.toolbarHidden = NO;
    _isFullScreen = NO;
    self.fullscreenOffButton.hidden = YES;
    _script = [FileLoader getScript];
    [HistoryTracker setHistoryIndex:0];
    _loadingSavedPage = NO;
    _shouldSaveHistory = YES;
    _historySaved = NO;
    [self loadURLFromString:self.url];
}
- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setActivityIndicator:nil];
    [self setFullscreenOffButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void) loadURLFromString:(NSString *)urlString {
	_finishedLoading = NO;
    _jsInjected = NO;
    self.url = urlString;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}
-(void)loadPageFromHTML:(NSString*)html{
	_finishedLoading = NO;
    _jsInjected = NO;
    NSURL* baseURL = [[NSBundle mainBundle] resourceURL];
    [self.webView loadHTMLString:html baseURL:baseURL];
}

#pragma mark - UIWebViewDelegate
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *url = request.URL.absoluteString;
    if ([url hasPrefix:@"command://"]) {    //page is finished loading
        self.webView.hidden = NO;
        [self.activityIndicator stopAnimating];
        self.title = [request.URL.query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self addToHistory];
		_finishedLoading = YES;
        NSLog(@"command done");
        return NO;
    }
    else if ([request.URL.host isEqualToString:@"tvtropes.org"]) {
        _jsInjected = NO;
        self.url = url;
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
    } else {
		return YES;
	}
}
-(void)webViewDidStartLoad:(UIWebView *)webView {
    self.webView.hidden = YES;
    [self.activityIndicator startAnimating];
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    NSLog(@"%@, %@", error,self.url);
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
        self.webView.hidden = NO;
        [self.activityIndicator stopAnimating];
		_finishedLoading = YES;
        [self addToHistory];
    }
}

-(void) addToHistory {
    if (_shouldSaveHistory) {
        NSString *html = [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        [HistoryItem addHistoryItemHTML:html withTitle:self.title andURL:self.url];
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

- (IBAction)back:(UIBarButtonItem *)sender {
    NSArray* history = [HistoryItem history];
    if ([HistoryTracker historyIndex] < history.count-1) {
        [HistoryTracker setHistoryIndex:[HistoryTracker historyIndex]+1];
        HistoryItem* previous = [history objectAtIndex:[HistoryTracker historyIndex]];
        self.url = previous.url;
        _shouldSaveHistory = NO;
        _loadingSavedPage = YES;
        [self loadPageFromHTML:previous.html];
    }
}

- (IBAction)forward:(UIBarButtonItem *)sender {
    if ([HistoryTracker historyIndex] > 0) {
        NSArray* history = [HistoryItem history];
        [HistoryTracker setHistoryIndex:[HistoryTracker historyIndex]-1];
        HistoryItem* next = [history objectAtIndex:[HistoryTracker historyIndex]];
        self.url = next.url;
        _shouldSaveHistory = NO;
        _loadingSavedPage = YES;
        [self loadPageFromHTML:next.html];
    }
}

#pragma mark - SavedPagesDelegate
-(void) savedPageController:(id)controller didSelectSavedPageWithHTML:(NSString *)html andURL:(NSString*)url {
    [controller dismissViewControllerAnimated:YES completion:nil];
    _loadingSavedPage = YES;
    self.url = url;
    [self loadPageFromHTML:html];
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

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [Bookmark saveBookmarkURL:self.url withTitle:self.title];
            break;
        case 1:
        {
            NSString *html = [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
            [Page savePageHTML:html withTitle:self.title andURL:self.url];
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
