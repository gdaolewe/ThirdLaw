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

@interface SearchViewController ()
    <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *searchWebView;
@end

@implementation SearchViewController

@synthesize searchWebView = _searchWebView;
@synthesize delegate = _delegate;

NSArray* _optionsArray;
NSMutableDictionary* _optionsDictionary;
NSString* _resultURL;

BOOL _titleSwitchOn;
BOOL _allSwitchOn;


- (void)viewDidLoad
{
    [super viewDidLoad];
    _optionsArray = @[@"Tropes",@"Anime & Manga",@"Comicbook",@"Fanfic",@"Film",@"Literature",@"Music",@"Tabletop Games",@"Theater",@"Video Games",@"Web Animation",@"Web Comics",@"Web Original",@"Western Animation",@"Real Life"];
    
    NSMutableArray* tempZeros = [NSMutableArray array];
    for (int i=0; i<_optionsArray.count; i++)
        [tempZeros insertObject:@0 atIndex:i];
    _optionsDictionary = [NSMutableDictionary dictionaryWithObjects:tempZeros forKeys:_optionsArray];
    _titleSwitchOn = NO;
    _allSwitchOn = YES;
    
}

- (void)viewDidUnload
{
    //[self setInfoButton:nil];
    [self setSearchWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    //NSString* baseURL = @"http://www.google.com/search?q=";
    //NSString* optionsURL = @"%20site:tvtropes.org";
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
    [self.searchWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

@end
