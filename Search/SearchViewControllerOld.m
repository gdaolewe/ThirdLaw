//
//  SearchViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 12/22/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchViewControllerOld.h"

@interface SearchViewControllerOld () <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, NSURLConnectionDelegate>

@end

@implementation SearchViewControllerOld

NSArray *_suggestionArray;
NSMutableData *_googleData;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _suggestionArray = [NSArray arrayWithObjects:@"hello", @"world", @"foo", @"bar", nil];
    _googleData = [NSMutableData data];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    }

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _suggestionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [_suggestionArray objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.searchDisplayController.searchBar.text = [_suggestionArray objectAtIndex:indexPath.row];
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        [searchText stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://google.com/complete/search?output=toolbar&q=site:tvtropes.org %@", searchText]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [connection start];
        
    }
        
}

#pragma mark - NSURLConnectionDelegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [_googleData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_googleData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSString *responseString = [[NSString alloc] initWithData:_googleData encoding:NSUTF8StringEncoding];
    
    NSLog(@"Response: %@",responseString);
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_googleData];
    [parser parse];
          
}
          
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Eror during connection: %@", [error description]);
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
