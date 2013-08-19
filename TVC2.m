//
//  TVC2.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "TVC2.h"
#import "IndexData.h"
#import "PageViewController.h"
#import "SearchViewController.h"

@interface TVC2 () <SearchViewDelegate>
@property IndexData *indexData;
@end

@implementation TVC2

@synthesize indexData = _indexData;
@synthesize categoryIndex = _categoryIndex;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _indexData = [IndexData sharedIndexData];
    self.title = [_indexData categoryNameAtIndex:self.categoryIndex];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Load page from index"] && [segue.destinationViewController respondsToSelector:@selector(url)]) {
        PageViewController *dvc = segue.destinationViewController;
        dvc.url = [_indexData urlForCategoryIndex:self.categoryIndex atIndex:[self.tableView indexPathForSelectedRow].row];
        //dvc.title = [_indexData exampleNameForCategoryIndex:self.categoryIndex atIndex:[self.tableView indexPathForSelectedRow].row];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    return [_indexData examplesCountForCategoryIndex:self.categoryIndex];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Index level 1 celll";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index level 1 cell"];
    }
    
    cell.textLabel.text = [_indexData exampleNameForCategoryIndex:self.categoryIndex atIndex:indexPath.row];
    [cell.textLabel setFont:[UIFont fontWithName:@"POORICH" size:17]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Load page from index" sender:self];
}

#pragma mark - SearchViewDelegate
-(void) searchViewController:(id)controller didSelectSearchResult:(NSString *)result {
    NSLog(@"select search result");
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"Load page from index" sender:self];
}

@end
