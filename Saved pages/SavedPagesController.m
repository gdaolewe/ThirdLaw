//
//  SavedFilesController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "SavedPagesController.h"
#import "HistoryItem.h"
#import "HistoryTracker.h"
#import "Bookmark.h"
#import "Page.h"
#import "PageViewController.h"

#define HISTORY     0
#define BOOKMARKS   1
#define SAVED_PAGES 2

@interface SavedPagesController () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *clearButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *tabBar;

@end

@implementation SavedPagesController

bool _editing = NO;

@synthesize delegate = _delegate;
@synthesize tableView = _tableView;
@synthesize doneButton = _doneButton;
@synthesize editButton = _editButton;
@synthesize clearButton = _clearButton;
@synthesize deleteButton = _deleteButton;
@synthesize toolbar = _toolbar;
@synthesize tabBar = _tabBar;

NSArray *history;
NSArray *bookmarks;
NSArray *pages;
NSMutableSet * _selectedEditRows;

- (IBAction)tabChanged:(UISegmentedControl *)sender {
    [self setupTab];
}

-(void) setupTab {
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    switch (self.tabBar.selectedSegmentIndex) {
        case HISTORY: {
            self.toolbar.items = [NSArray arrayWithObjects:self.clearButton, flexibleSpace, nil];
        }
            break;
        case BOOKMARKS: {
            self.toolbar.items = [NSArray arrayWithObjects:self.editButton, flexibleSpace, self.deleteButton, nil];
        }
            break;
        case SAVED_PAGES: {
            self.toolbar.items = [NSArray arrayWithObjects:self.editButton, flexibleSpace, self.deleteButton, nil];
        }
            break;
    }
    [self.tableView reloadData];
}

- (IBAction)done:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)edit:(UIBarButtonItem *)sender {
    if (self.tableView.editing) {   // done editing
        [self.tableView setEditing:NO animated:YES];
        sender.style = UIBarButtonItemStyleBordered;
        sender.title = @"Edit";
        [self.navigationItem setRightBarButtonItem:self.doneButton animated:NO];
        self.navigationItem.rightBarButtonItem = self.doneButton;
        self.doneButton.enabled = YES;
        self.tabBar.enabled = YES;
        NSMutableArray *items = [self.toolbar.items mutableCopy];
        [items removeObjectAtIndex:2];
        [self.toolbar setItems:items animated:YES];
    } else {                        // start editing
        [self.tableView setEditing:YES animated:YES];
        sender.style = UIBarButtonItemStyleDone;
        sender.title = @"Done";
        self.doneButton.enabled = NO;
        self.tabBar.enabled = NO;
        NSMutableArray* items = [self.toolbar.items mutableCopy];
        [items addObject:self.deleteButton];
        [self.toolbar setItems:items animated:YES];
    }
}

- (IBAction)clearHistory:(UIBarButtonItem *)sender {
    [HistoryItem clearHistory];
    history = [HistoryItem history];
    [self.tableView reloadData];
}

-(IBAction)deleteRows:(UIBarButtonItem *)sender {
    if (self.tabBar.selectedSegmentIndex == BOOKMARKS) {
        for (NSIndexPath *indexPath in _selectedEditRows)  {
            Bookmark *bookmark = [bookmarks objectAtIndex:indexPath.row];
            [Bookmark deleteBookmark:bookmark];
        }
        bookmarks = [Bookmark bookmarks];
    }
    else if (self.tabBar.selectedSegmentIndex == SAVED_PAGES) {
        for (NSIndexPath *indexPath in _selectedEditRows) {
            Page *page = (Page*)[pages objectAtIndex:indexPath.row];
            [Page deletePage:page];
        }
        pages = [Page pages];
    }
    [self.tableView deleteRowsAtIndexPaths:[_selectedEditRows allObjects] withRowAnimation:UITableViewRowAnimationAutomatic];
    _selectedEditRows = [NSMutableSet set];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    history = [HistoryItem history];
    bookmarks = [Bookmark bookmarks];
    pages = [Page pages];
    _selectedEditRows = [NSMutableSet set];
    NSMutableArray *items = [self.toolbar.items mutableCopy];
    [items removeObjectAtIndex:2];
    [self.toolbar setItems:items animated:YES];
    [self setupTab];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    switch (self.tabBar.selectedSegmentIndex) {
        case HISTORY:
            return [history count];
            break;
        case BOOKMARKS:
            return [bookmarks count];
            break;
        case SAVED_PAGES:
            return [pages count];
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    switch (self.tabBar.selectedSegmentIndex) {
        case HISTORY: {
            static NSString *cellIdentifier = @"History Item";
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"History Item"];
            }
            HistoryItem *item = (HistoryItem*)[history objectAtIndex:indexPath.row];
            if ([HistoryTracker historyIndex] == indexPath.row)
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", @">", item.title];
            else
                cell.textLabel.text = item.title;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Visited %@", [item dateString]];
        }
            break;
        case BOOKMARKS: {
            static NSString *cellIdentifier = @"Bookmark";
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Bookmark"];
            }
            Bookmark *bookmark = (Bookmark*)[bookmarks objectAtIndex:indexPath.row];
            cell.textLabel.text = bookmark.title;
        }
            break;
        case SAVED_PAGES: {
            static NSString *cellIdentifier = @"Saved Page";
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Saved Page"];
            }
            Page* page = (Page*)[pages objectAtIndex:indexPath.row];
            cell.textLabel.text = page.title;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Added %@", [page dateString]];
        }
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        [_selectedEditRows addObject:indexPath];
        self.deleteButton.enabled = YES;
    } else {
        switch (self.tabBar.selectedSegmentIndex) {
            case HISTORY:
            {
                HistoryItem *item = (HistoryItem*)[history objectAtIndex:indexPath.row];
                [HistoryTracker setHistoryIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectSavedPage:item];
            }
                break;
            case BOOKMARKS:
            {
                NSLog(@"bookmark selected");
                Bookmark *bookmark = (Bookmark*)[bookmarks objectAtIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectBookmarkWithURL:bookmark.url];
                
            }
                break;
            case SAVED_PAGES:
            {
                Page* page = (Page*)[pages objectAtIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectSavedPage:page];
            }
                break;
        }
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.editing) {
        [_selectedEditRows removeObject:indexPath];
        if (_selectedEditRows.count < 1)
            self.deleteButton.enabled = NO;
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setDoneButton:nil];
    [self setToolbar:nil];
    [self setDeleteButton:nil];
    [self setTabBar:nil];
    [self setEditButton:nil];
    [self setClearButton:nil];
    [super viewDidUnload];
}

@end
