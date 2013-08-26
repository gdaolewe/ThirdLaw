//
//  IndexTableViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/18/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "IndexTableViewController.h"
#import "IndexData.h"
#import "FileLoader.h"
#import "PageViewController.h"
#import "SavedPagesController.h"
#import "SearchViewController.h"
#import "Styles.h"

@interface IndexTableViewController () <SearchViewDelegate, SavedPagesDelegate>

@end

IndexData * _indexData;

@implementation IndexTableViewController

@synthesize indexDepth = _indexDepth;
@synthesize categoryIndex = _categoryIndex;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _indexData = [IndexData sharedIndexData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filesUpdated:) name:FILES_NOTIFICATION_NAME object:nil];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void) filesUpdated:(NSNotification*)notification {
    [_indexData loadHTML];
    [self.tableView reloadData];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index cell"];
    }
    // Configure the cell...
    switch (self.indexDepth) {
        case 0:
            cell.textLabel.text = [_indexData categoryNameAtIndex:indexPath.row];
            break;
        case 1: {
            NSString * url = [_indexData urlForCategoryIndex:self.categoryIndex atIndex:indexPath.row];
            if (!url) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.textLabel.text = [_indexData exampleNameForCategoryIndex:self.categoryIndex atIndex:indexPath.row];
        }
            break;
    }
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.indexDepth) {
        case 0: {
            IndexTableViewController *newIndexTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Index"];
            newIndexTVC.indexDepth = self.indexDepth + 1;
            newIndexTVC.title = [_indexData categoryNameAtIndex:indexPath.row];
            newIndexTVC.categoryIndex = indexPath.row;
            [self.navigationController pushViewController:newIndexTVC animated:YES];
        }
            break;
        case 1: {
            NSString * url = [_indexData urlForCategoryIndex:self.categoryIndex atIndex:indexPath.row];
            if (url) {
                PageViewController *page = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
                page.url = [_indexData urlForCategoryIndex:self.categoryIndex atIndex:indexPath.row];
                [self.navigationController pushViewController:page animated:YES];
            } 
        }
            break;
    }
}

#pragma mark - SavedPagesDelegate
-(void) savedPageController:(id)controller didSelectSavedPage:(id<GenericSavedPage>)page {
    [controller dismissViewControllerAnimated:YES completion:nil];
    PageViewController * pvc = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
    pvc.url = page.url;
    pvc.title = page.title;
    [pvc loadPageFromHTML:page.html];
    [self.navigationController pushViewController:pvc animated:YES];
}
-(void)savedPageController:(id)controller didSelectBookmarkWithURL:(NSString *)url {
    [controller dismissViewControllerAnimated:YES completion:nil];
    PageViewController * page = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
    page.url = url;
    [self.navigationController pushViewController:page animated:YES];
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
    } else if ([segue.identifier isEqualToString:@"IndexToSavedPagesSegue"]) {
        SavedPagesController *savedPages = (SavedPagesController*)segue.destinationViewController;
        savedPages.delegate = self;
    }
}

- (IBAction)home:(UIBarButtonItem *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)random:(UIBarButtonItem *)sender {
    PageViewController *page = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
    page.url = RANDOM_URL;
    [self.navigationController pushViewController:page animated:YES];
}

@end
