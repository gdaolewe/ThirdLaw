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
#import "NSString+URLEncoding.h"
#import "SavedPagesController.h"
#import "SearchResultData.h"
#import "SearchViewController.h"
#import "SearchOptionsTVC.h"
#import "ExternalWebViewController.h"
#import <dispatch/dispatch.h>
#import "Reachability.h"
#import "UserDefaultsHelper.h"

NSString *const RANDOM_URL;

@interface PageViewController () <UIWebViewDelegate, SavedPagesDelegate, SearchViewDelegate, UIActionSheetDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
-(void) loadURLFromString:(NSString *)urlString;

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIButton *fullscreenOffButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *backForwardCancelButton;
@property (strong, nonatomic) IBOutlet UIButton *rotationLockButton;
@property (strong, nonatomic) SearchOptionsTVC	*optionsController;

@end

@implementation PageViewController

NSString *const RANDOM_URL = @"http://tvtropes.org/pmwiki/randomitem.php";

@synthesize webView = _webView;
@synthesize fullscreenOffButton = _fullscreenOffButton;
@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize rotationLockButton = _rotationLockButton;
@synthesize url = _url;

NSString* _script;
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
    //self.webView.delegate = self;
    //self.navigationController.toolbarHidden = NO;
	
	
    _isFullScreen = NO;
    _backForwardButtonsShowing = NO;
    self.fullscreenOffButton.hidden = YES;
    _defaults = [NSUserDefaults standardUserDefaults];
    _script = [FileLoader getScript];
    _loadingSavedPage = NO;
    _shouldSaveHistory = YES;
    _historySaved = NO;
	[self setupNamespaces];
    if ([self.url isEqualToString:RANDOM_URL]) {
        [self loadRandomURL];
    } else if (self.url == nil) {
        NSArray *history = [HistoryItem history];
        HistoryItem *item;
        if (history.count > 0)
            item = [history objectAtIndex:[HistoryItem historyIndex]];
        if (item) { //load page where we last where
            [self savedPageController:nil didSelectSavedPage:item];
        } else {    //load home page
            _shouldSaveHistory = YES;
            self.url = @"http://tvtropes.org/pmwiki/pmwiki.php/Main/HomePage";
            [self loadPageFromHTML: [FileLoader getHomePage]];
        }
    } else {
        [self loadURLFromString:self.url];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(filesUpdated:)
												 name:FILES_NOTIFICATION_NAME object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupRotationLockButton];
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
	[self setMainView:nil];
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
            dispatch_sync(dispatch_get_main_queue(), ^{
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
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked || [request.URL.host isEqualToString:@"tvtropes.org"]) {
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

#pragma mark - SearchViewDelegate
-(void) searchViewController:(id)controller didSelectSearchResult:(NSString *)result {
    NSLog(@"select search result");
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self loadURLFromString:result];
}

- (IBAction)showSearch:(UIBarButtonItem *)sender {
	self.searchDisplayController.searchBar.hidden = NO;
	[self.searchDisplayController setActive:YES animated:YES];
}

#pragma mark - Search

NSArray *searchResults;

-(void) setupNamespaces {
	_mediaNamespacesDictionary = [NSMutableDictionary dictionary];
	for (NSString *namespace in MEDIA_NAMESPACES)
		[_mediaNamespacesDictionary setObject:[NSNumber numberWithBool:NO] forKey:namespace];
	_subPageNamespacesDictionary = [NSMutableDictionary dictionary];
	for (NSString *namespace in SUBPAGE_NAMESPACES)
		[_subPageNamespacesDictionary setObject:[NSNumber numberWithBool:NO] forKey:namespace];
	_momentsNamespacesDictionary = [NSMutableDictionary dictionary];
	for (NSString *namespace in MOMENTS_NAMESPACES)
		[_momentsNamespacesDictionary setObject:[NSNumber numberWithBool:NO] forKey:namespace];
}

#pragma mark - UISearchBarDelegate

-(void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
	self.optionsController = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchOptions"];
	self.optionsController.tableView.dataSource = self;
	self.optionsController.tableView.delegate = self;
	[self presentViewController:self.optionsController animated:YES completion:nil];
}

#pragma mark - UISearchDisplayDelegate

-(void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	self.searchDisplayController.searchBar.hidden = YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	if (searchString.length == 0)
		return NO;
	if ([searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0)
		return NO;
	searchString = [searchString urlEncode];
	
	NSString* siteQuery = @"";
	if (_allSwitchOn) {
        siteQuery = BASE_SITE_QUERY;
    } else {
        siteQuery = [SearchResultData siteQueryForNamespaceDictionaries:_mediaNamespacesDictionary, _subPageNamespacesDictionary, _momentsNamespacesDictionary, nil];
    }

	
	void (^doneBlock)(NSArray*) = ^(NSArray *results) {
		searchResults = results;
		[self.searchDisplayController.searchResultsTableView reloadData];
	};
	dispatch_queue_t queue = dispatch_queue_create("com.georgedw.lampshade.googlesearch", NULL);
	dispatch_async(queue, ^ {
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", BASE_SEARCH_URL, searchString, siteQuery]];
		NSLog(@"%@", url.absoluteString);
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		NSURLResponse *response;
		NSError *error;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (error)
			NSLog(@"error downloading data %@", error);
		else
			NSLog(@"downloaded google search data");
		NSArray * results = [SearchResultData parseData:data];
		dispatch_sync(dispatch_get_main_queue(), ^{
			doneBlock(results);
		});
	});
	return NO;
}

NSMutableDictionary *_mediaNamespacesDictionary;
NSMutableDictionary *_subPageNamespacesDictionary;
NSMutableDictionary *_momentsNamespacesDictionary;
BOOL _titleSwitchOn = NO;
BOOL _allSwitchOn = YES;
BOOL _mediaNamespacesOn = NO;
BOOL _subpageNamespacesOn = NO;
BOOL _momentsNamespacesOn = NO;

typedef enum {
	SearchOptionsSectionSearchTitles,
	SearchOptionsSectionSearchAll,
	SearchOptionsSectionMediaNamespaces,
	SearchOptionsSectionSubPageNamespaces,
	SearchOptionsSectionMomentsNamespaces
}SearchOptionsSection;

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return 1;
	else if (tableView == self.optionsController.tableView) {
		return _allSwitchOn? 2:5;
	}
	else
		return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.optionsController.tableView) {
		switch (section) {
			case SearchOptionsSectionSearchTitles:
				return nil;
				break;
			case SearchOptionsSectionSearchAll:
				return nil;
				break;
			case SearchOptionsSectionMediaNamespaces:
				return @"Media Namespaces";
				break;
			case SearchOptionsSectionSubPageNamespaces:
				return @"Subpage Namespaces";
				break;
			case SearchOptionsSectionMomentsNamespaces:
				return @"Moments Namespaces";
				break;
			default:
				return 0;
		}
	} else {
		return nil;
	}

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return searchResults.count;
	else if (tableView == self.optionsController.tableView) {
		switch (section) {
		case SearchOptionsSectionSearchTitles:
			return 1;
			break;
		case SearchOptionsSectionSearchAll:
			return 1;
			break;
		case SearchOptionsSectionMediaNamespaces:
			return MEDIA_NAMESPACES.count;
			break;
		case SearchOptionsSectionSubPageNamespaces:
			return SUBPAGE_NAMESPACES.count;
			break;
		case SearchOptionsSectionMomentsNamespaces:
			return MOMENTS_NAMESPACES.count;
			break;
		default:
			return 0;
		}
	}
	else
		return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		UITableViewCell *cell = nil;
		static NSString *cellIdentifier = @"Search Result";
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Search Result"];
		}
		NSDictionary *result = [searchResults objectAtIndex:indexPath.row];
		NSString *title = [result objectForKey:@"title"];
		title = [title stringByReplacingOccurrencesOfString:@" - Television Tropes & Idioms - TV Tropes" withString:@""];
		title = [title stringByReplacingOccurrencesOfString:@" - Television Tropes & Idioms" withString:@""];
		cell.textLabel.text = title;
		return cell;
	} else if (tableView == self.optionsController.tableView) {
		static NSString *CellIdentifier = @"Search Option Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:cell.frame];
		
		[cellSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index level 1 cell"];
		}
		switch (indexPath.section) {
			case SearchOptionsSectionSearchTitles:
				cell.textLabel.text = @"Search titles only";
				cell.accessoryType = _titleSwitchOn? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case SearchOptionsSectionSearchAll:
				cell.textLabel.text = @"Search all namespaces";
				cell.accessoryType = _allSwitchOn? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				break;
			case SearchOptionsSectionMediaNamespaces: {
				cell.textLabel.text = [MEDIA_NAMESPACES objectAtIndex:indexPath.row];
				BOOL rowSelected = ((NSNumber*)[_mediaNamespacesDictionary objectForKey:[MEDIA_NAMESPACES objectAtIndex:indexPath.row]]).boolValue;
				cell.accessoryType = rowSelected? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			}	break;
			case SearchOptionsSectionSubPageNamespaces: {
				cell.textLabel.text = [SUBPAGE_NAMESPACES objectAtIndex:indexPath.row];
				BOOL rowSelected = ((NSNumber*)[_subPageNamespacesDictionary objectForKey:[SUBPAGE_NAMESPACES objectAtIndex:indexPath.row]]).boolValue;
				cell.accessoryType = rowSelected? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			}	break;
			case SearchOptionsSectionMomentsNamespaces: {
				cell.textLabel.text = [MOMENTS_NAMESPACES objectAtIndex:indexPath.row];
				BOOL rowSelected = ((NSNumber*)[_momentsNamespacesDictionary objectForKey:[MOMENTS_NAMESPACES objectAtIndex:indexPath.row]]).boolValue;
				cell.accessoryType = rowSelected? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			}	break;
		}
		return cell;
	} else {
		return nil;
	}
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		[self.searchDisplayController setActive:NO animated:YES];
		self.searchDisplayController.searchBar.hidden = YES;
		NSDictionary *selectedResult = [searchResults objectAtIndex:indexPath.row];
		NSLog(@"loading link: %@", [selectedResult objectForKey:@"link"]);
		[self loadURLFromString:[selectedResult objectForKey:@"link"]];
	} else if (tableView == self.optionsController.tableView) {
		switch (indexPath.section) {
			case SearchOptionsSectionSearchTitles:
				_titleSwitchOn = !_titleSwitchOn;
				break;
			case SearchOptionsSectionSearchAll:
				_allSwitchOn = !_allSwitchOn;
				[tableView reloadData];
				break;
			case SearchOptionsSectionMediaNamespaces: {
				BOOL rowShouldBeSelected = !((NSNumber*)[_mediaNamespacesDictionary objectForKey:[MEDIA_NAMESPACES objectAtIndex:indexPath.row]]).boolValue;
				[_mediaNamespacesDictionary setObject:[NSNumber numberWithBool:rowShouldBeSelected] forKey:[MEDIA_NAMESPACES objectAtIndex:indexPath.row]];
				[tableView reloadData];
			}	break;
			case SearchOptionsSectionSubPageNamespaces: {
				BOOL rowShouldBeSelected = !((NSNumber*)[_subPageNamespacesDictionary objectForKey:[SUBPAGE_NAMESPACES objectAtIndex:indexPath.row]]).boolValue;
				[_subPageNamespacesDictionary setObject:[NSNumber numberWithBool:rowShouldBeSelected] forKey:[SUBPAGE_NAMESPACES objectAtIndex:indexPath.row]];
				[tableView reloadData];
			}	break;
			case SearchOptionsSectionMomentsNamespaces: {
				BOOL rowShouldBeSelected = !((NSNumber*)[_momentsNamespacesDictionary objectForKey:[MOMENTS_NAMESPACES objectAtIndex:indexPath.row]]).boolValue;
				[_momentsNamespacesDictionary setObject:[NSNumber numberWithBool:rowShouldBeSelected] forKey:[MOMENTS_NAMESPACES objectAtIndex:indexPath.row]];
				[tableView reloadData];
			}	break;
		}
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
