//
//  IndexTableViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/18/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "IndexTableViewController.h"
#import "IndexData.h"
#import "PageViewController.h"
#import "SearchViewController.h"

@interface IndexTableViewController () <SearchViewDelegate>

@end

IndexData * _indexData;

@implementation IndexTableViewController

@synthesize indexDepth = _indexDepth;
@synthesize categoryIndex = _categoryIndex;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.categoryIndex = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _indexData = [IndexData sharedIndexData];
    self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0.03922 green:0.19608 blue:0.4 alpha:1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.indexDepth) {
        case 0:
            return [_indexData categoryCount];
            break;
        case 1:
            return [_indexData examplesCountForCategoryIndex:self.categoryIndex];
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Index cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index cell"];
    }
    // Configure the cell...
    //cell.textLabel.font = [UIFont fontWithName:@"NoticiaText-Bold" size:[UIFont labelFontSize]];
    switch (self.indexDepth) {
        case 0:
            cell.textLabel.text = [_indexData categoryNameAtIndex:indexPath.row];
            break;
        case 1:
            cell.textLabel.text = [_indexData exampleNameForCategoryIndex:self.categoryIndex atIndex:indexPath.row];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%d", self.indexDepth);
    switch (self.indexDepth) {
        case 0: {
            IndexTableViewController *newIndexTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Index"];
            newIndexTVC.indexDepth = self.indexDepth + 1;
            newIndexTVC.categoryIndex = indexPath.row;
            newIndexTVC.title = [_indexData categoryNameAtIndex:indexPath.row];
            [self.navigationController pushViewController:newIndexTVC animated:YES];
        }
            break;
        case 1: {
            PageViewController *page = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
            page.url = [_indexData urlForCategoryIndex:[_indexData categoryIndex] atIndex:indexPath.row];
            [self.navigationController pushViewController:page animated:YES];
        }
            break;
    }
}

#pragma mark - SearchViewDelegate
-(void)searchViewController:(id)controller didSelectSearchResult:(NSString *)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    PageViewController *page = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
    page.url = result;
    [self.navigationController pushViewController:page animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"IndexToSearchSegue"]) {
        UINavigationController *searchNav = (UINavigationController*)segue.destinationViewController;
        ((SearchViewController*)searchNav.topViewController).delegate = self;
    }
}

@end
