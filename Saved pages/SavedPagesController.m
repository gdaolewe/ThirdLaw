//
//  SavedFilesController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "SavedPagesController.h"
#import "HistoryItem.h"
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

NSUserDefaults *defaults;
NSArray *_history;
NSArray *_bookmarks;
NSArray *_pages;
NSMutableSet * _selectedEditRows;

- (void)viewDidLoad
{
    [super viewDidLoad];
    defaults = [NSUserDefaults standardUserDefaults];
    _selectedEditRows = [NSMutableSet set];
    NSMutableArray *items = [self.toolbar.items mutableCopy];
    [items removeObjectAtIndex:2];
    [self.toolbar setItems:items animated:YES];
    self.tabBar.selectedSegmentIndex = ((NSNumber*)[defaults objectForKey:@"SavedPagesStartingTab"]).intValue;
    [self setupTab];
}

-(void) fetchTableDataAsyncForType:(int)type {
    switch (type) {
        case HISTORY: {
                dispatch_queue_t backgroundQueue =  dispatch_queue_create("com.georgedw.Lampshade.FetchHistory", NULL);
                dispatch_async(backgroundQueue, ^{
                    _history = [HistoryItem history];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (_history.count == 0)
                            self.clearButton.enabled = NO;
                        else
                            self.clearButton.enabled = YES;
                        [self.tableView reloadData];
                    });
                });
        }
        break;
        case BOOKMARKS: {
                dispatch_queue_t backgroundQueue =  dispatch_queue_create("com.georgedw.Lampshade.FetchBookmarks", NULL);
                dispatch_async(backgroundQueue, ^{
                    _bookmarks = [Bookmark bookmarks];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (_bookmarks.count == 0)
                            self.editButton.enabled = NO;
                        else
                            self.editButton.enabled = YES;
                        [self.tableView reloadData];
                    });
                });
        }
        break;
        case SAVED_PAGES: {
                dispatch_queue_t backgroundQueue =  dispatch_queue_create("com.georgedw.Lampshade.FetchPages", NULL);
                dispatch_async(backgroundQueue, ^{
                    _pages = [Page pages];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (_pages.count == 0)
                            self.editButton.enabled = NO;
                        else
                            self.editButton.enabled = YES;
                        [self.tableView reloadData];
                    });
                });
        }
        break;
    }
}

- (IBAction)tabChanged:(UISegmentedControl *)sender {
    [defaults setInteger:sender.selectedSegmentIndex forKey:@"SavedPagesStartingTab"];
    [self setupTab];
}

-(void) setupTab {
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    int tabIndex = self.tabBar.selectedSegmentIndex;
    [self fetchTableDataAsyncForType:tabIndex];
    switch (tabIndex) {
        case HISTORY:
            self.toolbar.items = [NSArray arrayWithObjects:self.clearButton, flexibleSpace, nil];
            break;
        case BOOKMARKS:
            self.toolbar.items = [NSArray arrayWithObjects:self.editButton, flexibleSpace, nil];
            break;
        case SAVED_PAGES:
            self.toolbar.items = [NSArray arrayWithObjects:self.editButton, flexibleSpace, nil];
            break;
    }
    [self.tableView reloadData];
}

- (IBAction)done:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)edit:(UIBarButtonItem *)sender {
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (self.tableView.editing) {   // done editing
        [self.tableView setEditing:NO animated:YES];
        sender.style = UIBarButtonItemStyleBordered;
        sender.title = @"Edit";
        [self.navigationItem setRightBarButtonItem:self.doneButton animated:NO];
        self.navigationItem.rightBarButtonItem = self.doneButton;
        self.doneButton.enabled = YES;
        self.tabBar.enabled = YES;
        NSArray *items = [NSArray arrayWithObjects:self.editButton, flexibleSpace, nil];
        [self.toolbar setItems:items animated:YES];
    } else if ([self tableView:self.tableView numberOfRowsInSection:0] > 0) {                        // start editing
        [self.tableView setEditing:YES animated:YES];
        sender.style = UIBarButtonItemStyleDone;
        sender.title = @"Done";
        self.doneButton.enabled = NO;
        self.tabBar.enabled = NO;
        NSArray *items = [NSArray arrayWithObjects:self.editButton, flexibleSpace, self.deleteButton, nil];
        [self.toolbar setItems:items animated:YES];
    }
}

- (IBAction)clearHistory:(UIBarButtonItem *)sender {
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.georgedw.Lampshade.ClearHistory", NULL);
    dispatch_async(backgroundQueue, ^{
        [HistoryItem clearHistory];
        _history = [HistoryItem history];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_history.count == 0)
                self.clearButton.enabled = NO;
            [self.tableView reloadData];
        });
    });
}

-(IBAction)deleteRows:(UIBarButtonItem *)sender {
    int tabIndex = self.tabBar.selectedSegmentIndex;
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.georgedw.Lampshade.DeletePages", NULL);
    dispatch_async(backgroundQueue, ^ {
        if (tabIndex == BOOKMARKS) {
            for (NSIndexPath *indexPath in _selectedEditRows)  {
                Bookmark *bookmark = [_bookmarks objectAtIndex:indexPath.row];
                [Bookmark deleteBookmark:bookmark];
            }
            _bookmarks = [Bookmark bookmarks];
        }
        else if (tabIndex == SAVED_PAGES) {
            for (NSIndexPath *indexPath in _selectedEditRows) {
                Page *page = (Page*)[_pages objectAtIndex:indexPath.row];
                [Page deletePage:page];
            }
            _pages = [Page pages];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView deleteRowsAtIndexPaths:[_selectedEditRows allObjects] withRowAnimation:UITableViewRowAnimationAutomatic];
            _selectedEditRows = [NSMutableSet set];
            self.deleteButton.enabled = NO;
            if ([self tableView:self.tableView numberOfRowsInSection:0] == 0) {
                [self edit:self.editButton];
                self.editButton.enabled = NO;
            };
        });
    });
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
            return [_history count];
            break;
        case BOOKMARKS:
            return [_bookmarks count];
            break;
        case SAVED_PAGES:
            return [_pages count];
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
            HistoryItem *item = (HistoryItem*)[_history objectAtIndex:indexPath.row];
            if ([HistoryItem historyIndex] == indexPath.row)
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
            Bookmark *bookmark = (Bookmark*)[_bookmarks objectAtIndex:indexPath.row];
            cell.textLabel.text = bookmark.title;
            cell.detailTextLabel.text = bookmark.url;
        }
            break;
        case SAVED_PAGES: {
            static NSString *cellIdentifier = @"Saved Page";
            
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Saved Page"];
            }
            Page* page = (Page*)[_pages objectAtIndex:indexPath.row];
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
                HistoryItem *item = (HistoryItem*)[_history objectAtIndex:indexPath.row];
                [HistoryItem setHistoryIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectSavedPage:item];
            }
                break;
            case BOOKMARKS:
            {
                NSLog(@"bookmark selected");
                Bookmark *bookmark = (Bookmark*)[_bookmarks objectAtIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectBookmarkWithURL:bookmark.url];
                
            }
                break;
            case SAVED_PAGES:
            {
                Page* page = (Page*)[_pages objectAtIndex:indexPath.row];
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
