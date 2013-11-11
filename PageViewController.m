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
#import <MMDrawerBarButtonItem.h>
#import "Bookmark.h"
#import "Page.h"
#import "NSString+URLEncoding.h"
#import "SearchResultData.h"
#import "SearchOptionsTVC.h"
#import "ExternalWebViewController.h"
#import <dispatch/dispatch.h>
#import "Reachability.h"
#import "UserDefaultsHelper.h"

NSString *const RANDOM_URL;

@interface PageViewController () <UIWebViewDelegate, UIActionSheetDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
-(void) loadURLFromString:(NSString *)urlString;

@property (strong, nonatomic) IBOutlet UIButton *fullscreenOffButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *backForwardCancelButton;
@property (strong, nonatomic) IBOutlet UIButton *rotationLockButton;
@property (strong, nonatomic) SearchOptionsTVC	*optionsController;
@property (strong, nonatomic) IBOutlet UITableView *searchResultsTableView;

//toolbar items
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *randomToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *actionsToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *savedToolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fullscreenToolbarItem;

@end

@implementation PageViewController

NSString *const HOME_URL = @"http://tvtropes.org/pmwiki/pmwiki.php/Main/HomePage";
NSString *const RANDOM_URL = @"http://tvtropes.org/pmwiki/randomitem.php";

@synthesize webView = _webView;
@synthesize fullscreenOffButton = _fullscreenOffButton;
@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize rotationLockButton = _rotationLockButton;
@synthesize url = _url;

NSString *_script;
NSUserDefaults *_defaults;

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
	[self showDefaultToolbarItems];
	self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    _isFullScreen = NO;
    _backForwardButtonsShowing = NO;
    self.fullscreenOffButton.hidden = YES;
    _defaults = [NSUserDefaults standardUserDefaults];
	if ([_defaults integerForKey:USER_PREF_START_VIEW] == USerPrefStartViewExternal) {
		ExternalWebViewController *webVC = [self.storyboard instantiateViewControllerWithIdentifier:@"External web view"];
		[self.navigationController pushViewController:webVC animated:NO];
	}
	[self setFullscreen:[_defaults boolForKey:USER_PREF_FULLSCREEN]];
    _script = [FileLoader getScript];
    _loadingSavedPage = NO;
    _shouldSaveHistory = YES;
    _historySaved = NO;
	NSLog(@"%@", self.url);
    if (self.url == nil) {
        NSArray *history = [HistoryItem history];
        HistoryItem *item;
        if (history.count > 0)
            item = [history objectAtIndex:[HistoryItem historyIndex]];
        if (item) { //load page where we last were
            [self savedPageController:nil didSelectSavedPage:item];
        } else {    //if there's no history, load home page
            _shouldSaveHistory = YES;
            [self loadHomePage];
        }
    } else {
		NSLog(@"self.url");
        [self loadURLFromString:self.url];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(filesUpdated:)
												 name:FILES_NOTIFICATION_NAME object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupRotationLockButton];
	self.mm_drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureModePanningNavigationBar;
	[_defaults setInteger:UserPrefStartViewPage forKey:USER_PREF_START_VIEW];
	[_defaults synchronize];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showRotationLockButton)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
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
    [self setRotationLockButton:nil];
	[self setSearchResultsTableView:nil];
	[self setSettingsToolbarItem:nil];
	[self setRandomToolbarItem:nil];
	[self setActionsToolbarItem:nil];
	[self setSavedToolbarItem:nil];
	[self setFullscreenToolbarItem:nil];
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

-(void)showDefaultToolbarItems {
	UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[self.settingsToolbarItem, space, self.randomToolbarItem, space, self.actionsToolbarItem, space, self.savedToolbarItem, space, self.fullscreenToolbarItem];
}

-(void) filesUpdated:(NSNotification*)notification {
    _script = [FileLoader getScript];
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
    if ([self checkReachable:YES]) {
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

-(void) loadHomePage {
	self.url = HOME_URL;
	_loadingSavedPage = YES;
	[self loadPageFromHTML: [FileLoader getHomePage]];
}

-(void) loadRandomURL {
	self.url = RANDOM_URL;
    if ([self checkReachable:YES]) {
        [self setPageHidden:YES];
        backgroundQueue = dispatch_queue_create("com.georgedw.Lampshade.RandomURLConnection", NULL);
        void (^doneBlock)(NSURLResponse*, NSData*) = ^(NSURLResponse *response, NSData *data) {
            self.url = response.URL.absoluteString;
            [self loadPageFromHTML:[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding]];
        };
        dispatch_async(backgroundQueue, ^(void) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:RANDOM_URL]];
            NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
            dispatch_sync(dispatch_get_main_queue(), ^{
                doneBlock(response, data);
            });
        });
		dispatch_release(backgroundQueue);
    }
}

-(BOOL) checkReachable:(BOOL)withMessage {
    Reachability *networkReachability = [Reachability reachabilityWithHostName:@"tvtropes.org"];
    NetworkStatus networkStatus = networkReachability.currentReachabilityStatus;
    if (networkStatus == NotReachable && withMessage) {
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
    else if ([request.URL.host isEqualToString:@"tvtropes.org"] && [[request.URL.pathComponents objectAtIndex:2] isEqualToString:@"pmwiki.php"]) {
		NSLog(@"%@", [request.URL.pathComponents objectAtIndex:2]);
        self.url = url;
        [self setPageHidden:YES];
        _jsInjected = NO;
        NSData* htmlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.url]];
        NSString* htmlString = [[NSString alloc] initWithData:htmlData encoding:NSISOLatin1StringEncoding];
        NSURL* baseURL = [[NSBundle mainBundle] resourceURL];
        [webView loadHTMLString:htmlString baseURL:baseURL];
        
        return NO;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
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
		NSLog(@"%d", _script.length);
        _loadingSavedPage = NO;
        [self setPageHidden:NO];
		//hacky fix to make spoilers function on saved pages
		[self.webView stringByEvaluatingJavaScriptFromString:@"$('.spoiler').bind('click tap', function(){if (!$(this).hasClass('spoilerClick')){event.preventDefault();}$(this).toggleClass('spoilerClick');});"];
		_finishedLoading = YES;
        [self addToHistory];
    }
}

-(void) addToHistory {
    if (_shouldSaveHistory) {
        NSString *html = [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        [HistoryItem addHistoryItemAsyncWithHTML:html title:self.title andURL:self.url];
        //[HistoryItem clearCache];
        _historySaved = YES;
    } else {
        _shouldSaveHistory = YES;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
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

#pragma mark - Navigation
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
    [HistoryItem clearCache];
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
    [HistoryItem clearCache];
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

#pragma mark - Search

NSArray *searchResults;
NSMutableArray *previousSearches;
NSMutableArray *filteredPreviousSearches;
BOOL showingPreviousSearches = NO;

- (IBAction)showSearch:(UIBarButtonItem *)sender {
	//clear out results from previous search
	searchResults = [NSArray array];
	previousSearches = [[_defaults arrayForKey:USER_PREF_PREVIOUS_SEARCHES] mutableCopy];
	filteredPreviousSearches = [previousSearches mutableCopy];
	showingPreviousSearches = YES;
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.toolbarHidden = YES;
	self.searchDisplayController.searchBar.hidden = NO;
	[self.searchDisplayController.searchBar becomeFirstResponder];
	[self.searchDisplayController setActive:YES animated:YES];
}

-(void)endSearch:(UIBarButtonItem*)sender {
	self.searchDisplayController.searchBar.hidden = YES;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	self.navigationController.toolbarHidden = NO;
	self.searchResultsTableView.hidden = YES;
	[self showDefaultToolbarItems];
	_willShowSearchResultsTable = NO;
}

#pragma mark - UISearchBarDelegate

BOOL _willShowSearchResultsTable = NO;

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self endSearch:nil];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	NSString* searchString = searchBar.text;
	if (searchString.length == 0)
		return;
	if ([searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0)
		return;
	
	//add this search term to search history
	showingPreviousSearches = NO;
	[previousSearches addObject:searchString];
	if (previousSearches.count > 20)
		[previousSearches removeObjectAtIndex:0];
	[_defaults setObject:previousSearches forKey:USER_PREF_PREVIOUS_SEARCHES];
	[_defaults synchronize];
	//url encode the search AFTER adding to history, as we want the history to show terms as entered
	searchString = [searchString urlEncode];
	NSLog(@"%@", searchString);
	void (^doneBlock)(NSArray*) = ^(NSArray *results) {
		searchResults = results;
		self.searchDisplayController.searchResultsTableView.hidden = NO;
		[self.searchDisplayController.searchResultsTableView reloadData];
	};
	dispatch_queue_t queue = dispatch_queue_create("com.georgedw.lampshade.googlesearch", NULL);
	dispatch_async(queue, ^ {
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", BASE_SEARCH_URL, searchString, BASE_SITE_QUERY]];
		NSLog(@"%@", url.absoluteString);
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		NSURLResponse *response;
		NSError *error;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (error)
			NSLog(@"error downloading google search data %@", error);
		else
			NSLog(@"downloaded google search data");
		NSArray * results = [SearchResultData parseData:data];
		dispatch_sync(dispatch_get_main_queue(), ^{
			doneBlock(results);
		});
	});
}

#pragma mark - UISearchDisplayDelegate

-(void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	[self endSearch:nil];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	showingPreviousSearches = YES;
	if ([searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
		//for blank search text show all previous searches unfiltered
		filteredPreviousSearches = [previousSearches mutableCopy];
	} else {
		//grab search terms in history in which current entered text occurs & location of occurrence
		NSMutableArray *termsWithLocations = [NSMutableArray array];
		for (NSString *term in previousSearches) {
			NSRange range = [term rangeOfString:searchString options:NSCaseInsensitiveSearch];
			if (range.location != NSNotFound)
				[termsWithLocations addObject:
				 @{@"term": term,
				   @"location": [NSNumber numberWithInteger:range.location]}
				 ];
		}
		//sort based on occurrence location: want terms that have current text occurring earlier to appear first
		[termsWithLocations sortUsingComparator:^NSComparisonResult(id a, id b)  {
			NSNumber *first = [(NSDictionary*)a objectForKey:@"location"];
			NSNumber *second = [(NSDictionary*)b objectForKey:@"location"];
			return [first compare:second];
		}];
		//then put sorted terms in our filtered search terms array
		filteredPreviousSearches = [NSMutableArray array];
		for (NSDictionary *tWithL in termsWithLocations)
			[filteredPreviousSearches addObject:[tWithL objectForKey:@"term"]];
	}
	return YES;
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (showingPreviousSearches)
		return filteredPreviousSearches.count;
	else if (tableView == self.searchDisplayController.searchResultsTableView)
		return searchResults.count;
	else
		return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (showingPreviousSearches) {
		UITableViewCell *cell = nil;
		static NSString *cellIdentifier = @"SearchSuggestion";
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Search Result"];
		}
		cell.textLabel.text = [filteredPreviousSearches objectAtIndex:indexPath.row];
		return cell;

	} else if (tableView == self.searchDisplayController.searchResultsTableView) {
		UITableViewCell *cell = nil;
		static NSString *cellIdentifier = @"SearchSuggestion";
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Search Result"];
		}
		NSDictionary *result = [searchResults objectAtIndex:indexPath.row];
		NSString *title = [result objectForKey:@"title"];
		title = [title stringByReplacingOccurrencesOfString:@" - Television Tropes & Idioms - TV Tropes" withString:@""];
		title = [title stringByReplacingOccurrencesOfString:@" - Television Tropes & Idioms" withString:@""];
		cell.textLabel.text = title;
		cell.detailTextLabel.text = [result objectForKey:@"description"];
		return cell;
	} else {
		return nil;
	}
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (showingPreviousSearches) {
		//put the selected history search term in the search bar
		self.searchDisplayController.searchBar.text = [filteredPreviousSearches objectAtIndex:indexPath.row];
	}
	else if (tableView == self.searchDisplayController.searchResultsTableView) {
		[self.searchDisplayController setActive:NO animated:YES];
		self.searchDisplayController.searchBar.hidden = YES;
		[self endSearch:nil];
		NSDictionary *selectedResult = [searchResults objectAtIndex:indexPath.row];
		NSLog(@"loading link: %@", [selectedResult objectForKey:@"link"]);
		[self loadURLFromString:[selectedResult objectForKey:@"link"]];
	}
}

#pragma mark - UIActionSheetDelegate

#define BOOKMARK_BUTTON 0
#define SAVE_BUTTON		1
#define SAFARI_BUTTON	2

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
		case SAFARI_BUTTON:
			if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.url]])
				NSLog(@"%@%@",@"Failed to open url:",self.url);
			break;
        default:
            NSLog(@"Cancelled");
            break;
    }
}

- (IBAction)saveActions:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Bookmark", @"Save for offline reading", @"Open in Safari", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)toggleFullscreen:(UIBarButtonItem *)sender {
    [self setFullscreen:!_isFullScreen];
}

CGRect notFullscreenDrawerControllerFrame;

-(void)setFullscreen:(BOOL)fullscreen {
	_isFullScreen = fullscreen;
	[_defaults setBool:fullscreen forKey:USER_PREF_FULLSCREEN];
	if (fullscreen) {
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        self.fullscreenOffButton.hidden = NO;
		notFullscreenDrawerControllerFrame = self.mm_drawerController.view.frame;
		self.mm_drawerController.view.frame = self.view.window.bounds;
	} else {
		[[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.fullscreenOffButton.hidden = YES;
		self.mm_drawerController.view.frame = notFullscreenDrawerControllerFrame;
	}
}

- (IBAction)toggleRotationLock:(UIButton *)sender {
    BOOL rotationLocked = [_defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    if (rotationLocked) {   //unlock rotation
        [_defaults setBool:NO forKey:USER_PREF_ROTATION_LOCKED];
        [self.class attemptRotationToDeviceOrientation];
    } else {    //lock rotation to current orientation
        [_defaults setBool:YES forKey:USER_PREF_ROTATION_LOCKED];
        [_defaults setInteger:self.interfaceOrientation forKey:USER_PREF_ROTATION_ORIENTATION];
    }
    [_defaults synchronize];
    [self setupRotationLockButton];
}

-(void)setupRotationLockButton {
    BOOL rotationLocked = [_defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    if (rotationLocked) {
        [self.rotationLockButton setImage:[UIImage imageNamed:@"locked.png"] forState:UIControlStateNormal];
    } else {
        [self.rotationLockButton setImage:[UIImage imageNamed:@"unlocked.png"] forState:UIControlStateNormal];
    }
}

NSTimer *_pageLockHideTimer;

-(void) showRotationLockButton {
	self.rotationLockButton.hidden = NO;
	if (_pageLockHideTimer != nil)
		[_pageLockHideTimer invalidate];
	_pageLockHideTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideRotationLockButtonAfterTimer:) userInfo:nil repeats:NO];
}
-(void) hideRotationLockButtonAfterTimer:(NSTimer*)theTimer {
	[self.rotationLockButton setHidden:YES];
}

-(void) leftDrawerButtonPress:(id)sender {
	NSLog(@"left drawer button press");
	[self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

//iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    BOOL rotationLocked = [_defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    NSInteger rotationOrientation = [_defaults integerForKey:USER_PREF_ROTATION_ORIENTATION];
    if (rotationLocked) {
        if (interfaceOrientation == rotationOrientation)
            return YES;
        else if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
                 && (rotationOrientation == UIInterfaceOrientationLandscapeLeft || rotationOrientation == UIInterfaceOrientationLandscapeRight))
            return YES;
        else
            return NO;
        return (UIInterfaceOrientationPortrait == interfaceOrientation);
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
	
}



@end
