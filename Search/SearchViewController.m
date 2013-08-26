//
//  SearchViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "SearchViewController.h"
#import "NSString+URLEncoding.h"
#import "PageViewController.h"
#import "Reachability.h"
#import "UserDefaultsHelper.h"

@interface SearchViewController ()
    <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIWebView *searchWebView;
@property (strong, nonatomic) IBOutlet UIButton *rotationLockButton;
@end

@implementation SearchViewController

@synthesize searchBar = _searchBar;
@synthesize searchWebView = _searchWebView;
@synthesize delegate = _delegate;
@synthesize rotationLockButton = _rotationLockButton;

NSUserDefaults *_defaults;
NSArray* _optionsArray;
NSMutableDictionary* _optionsDictionary;
NSString* _resultURL;

BOOL _titleSwitchOn;
BOOL _allSwitchOn;


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *searchString = [[NSUserDefaults standardUserDefaults] objectForKey:@"SearchString"];
    if (![searchString isEqualToString:@""])
        self.searchBar.text = searchString;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    _optionsArray = @[@"Tropes",@"Anime & Manga",@"Comicbook",@"Fanfic",@"Film",@"Literature",@"Music",@"Tabletop Games",@"Theater",@"Video Games",@"Web Animation",@"Web Comics",@"Web Original",@"Western Animation",@"Real Life"];
    
    NSMutableArray* tempZeros = [NSMutableArray array];
    for (int i=0; i<_optionsArray.count; i++)
        [tempZeros insertObject:@0 atIndex:i];
    _optionsDictionary = [NSMutableDictionary dictionaryWithObjects:tempZeros forKeys:_optionsArray];
    _titleSwitchOn = NO;
    _allSwitchOn = YES;
	_defaults = [NSUserDefaults standardUserDefaults];
}

- (void)viewDidUnload
{
    [self setSearchWebView:nil];
    [self setSearchBar:nil];
	[self setRotationLockButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupRotationLockButton];
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showRotationLockButton)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (IBAction)done:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Search Options segue"]) {
        UITableViewController *dvc = segue.destinationViewController;
        dvc.tableView.delegate = self;
        dvc.tableView.dataSource = self;
    }
    else if ([segue.identifier isEqualToString:@"Load page from search"] && [segue.destinationViewController respondsToSelector:@selector(url)]) {
        PageViewController *dvc = segue.destinationViewController;
        dvc.url = _resultURL;
    }
        
}

-(BOOL) checkReachable {
    Reachability *networkReachability = [Reachability reachabilityWithHostName:@"google.com"];
    NetworkStatus networkStatus = networkReachability.currentReachabilityStatus;
    if (networkStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No connection to Google.com"
                                                        message:@"Check your internet connection or browse offline"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    return networkStatus != NotReachable;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _allSwitchOn? 2:3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section==2? _optionsArray.count:1;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Search Option Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:cell.frame];
    [cellSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index level 1 cell"];
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Search titles only";
        cellSwitch.on = _titleSwitchOn;
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Search all";
        cellSwitch.on = _allSwitchOn;
    } else {
        cell.textLabel.text = [_optionsArray objectAtIndex:indexPath.row];
        cellSwitch.on = [[_optionsDictionary objectForKey:[_optionsArray objectAtIndex:indexPath.row]] boolValue];
    }
   
    cell.accessoryView = cellSwitch;
    return cell;
}

#pragma mark - Table view delegate

-(void) switchChanged: (UISwitch*)sender {
    UITableViewCell* cell = ((UITableViewCell*)sender.superview);
    UITableView* table = ((UITableView*)cell.superview);
    NSIndexPath* indexPath = [table indexPathForCell:cell];
    
    if (indexPath.section == 0) {
        _titleSwitchOn = sender.on;
    }
    else if (indexPath.section == 1) {
        _allSwitchOn = sender.on;
        [table reloadData];
    } else {
        [_optionsDictionary setObject:[NSNumber numberWithBool:sender.on]
                               forKey:[_optionsArray objectAtIndex:indexPath.row]];
    }
}

#pragma mark - Search bar delegate

#define BASE_URL @"http://www.google.com/search?q="
#define BASE_SITE_QUERY @"+site:tvtropes.org"

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [[NSUserDefaults standardUserDefaults] setObject:searchBar.text forKey:@"SearchString"];
    NSString* siteQuery = @"";
    if (_allSwitchOn) {
        siteQuery = BASE_SITE_QUERY;
    } else {
        BOOL useOR = YES;
        for (int i=0; i<_optionsArray.count; i++) {
            NSString* key = [_optionsArray objectAtIndex:i];
            if ([[_optionsDictionary objectForKey:key] isEqualToNumber:@1]) {
                if (!useOR) {
                    siteQuery = [siteQuery stringByAppendingString:@"+%7C"];
                } else {
                useOR = NO;
                }
                siteQuery = [siteQuery stringByAppendingFormat:@"%@%@",@"+site:tvtropes.org/pmwiki/pmwiki.php/",key];
            }
        }
        if (siteQuery.length == 0)
            siteQuery = BASE_SITE_QUERY;
    }
    NSString* searchText = [searchBar.text urlEncode];
    if (_titleSwitchOn)
        searchText = [@"intitle:" stringByAppendingString:searchText];
    NSString* url = [NSString stringWithFormat:@"%@%@%@",BASE_URL,searchText,siteQuery];
    [self loadURLFromString:url];
    [searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Web view delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.host isEqualToString:@"www.google.com"]) {
        [self checkReachable];
        return YES;
    } else if ([request.URL.host isEqualToString:@"tvtropes.org"]) {
        _resultURL = request.URL.absoluteString;
        NSLog(@"%@", self.delegate.class);
        [self.delegate searchViewController:self didSelectSearchResult:_resultURL];
        return NO;
    } else {
        return NO;
    }
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
  [self.searchWebView stringByEvaluatingJavaScriptFromString:@"window.alert=null"];  
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.searchWebView stringByEvaluatingJavaScriptFromString:@"function findPos(obj) {var curtop = 0;if (obj.offsetParent) {do {curtop += obj.offsetTop;} while (obj = obj.offsetParent);return [curtop];}}window.scroll(0,findPos(document.getElementById('rcnt')));"];
    [self.searchWebView stringByEvaluatingJavaScriptFromString:@"window.alert=null"];
    
}

-(void) loadURLFromString:(NSString *)urlString {
    if ([self checkReachable])
        [self.searchWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
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

NSTimer *_lockHideTimer;

-(void) showRotationLockButton {
	self.rotationLockButton.hidden = NO;
	if (_lockHideTimer != nil)
		[_lockHideTimer invalidate];
	_lockHideTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideRotationLockButtonAfterTimer:) userInfo:nil repeats:NO];
}

-(void) hideRotationLockButtonAfterTimer:(NSTimer*)theTimer {
	self.rotationLockButton.hidden = YES;
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
