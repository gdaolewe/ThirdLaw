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
#import "UserDefaultsHelper.h"

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
@property (strong, nonatomic) IBOutlet UIButton *rotationLockButton;

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
@synthesize rotationLockButton = _rotationLockButton;

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
    self.tabBar.selectedSegmentIndex = [defaults integerForKey:USER_PREF_SAVED_PAGES_STARTING_TAB];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHistory:) name:HISTORY_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBookmarks:) name:BOOKMARKS_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePages:) name:PAGES_NOTIFICATION_NAME object:nil];
    [self setupTab];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupRotationLockButton];
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showRotationLockButton)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void) updateHistory:(NSNotification*)notification {
    _history = [HistoryItem history];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
-(void) updateBookmarks:(NSNotification*)notification {
    _bookmarks = [Bookmark bookmarks];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
-(void) updatePages:(NSNotification*)notification {
    _pages = [Page pages];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

-(void) fetchTableDataAsyncForType:(int)type {
    switch (type) {
        case HISTORY: {
            [HistoryItem fetchHistoryAsync];
            _bookmarks = nil;
            _pages = nil;
            [Bookmark clearCache];
            [Page clearCache];
        }
        break;
        case BOOKMARKS: {
            [Bookmark fetchBookmarksAsync];
            _history = nil;
            _pages = nil;
            [HistoryItem clearCache];
            [Page clearCache];
        }
        break;
        case SAVED_PAGES: {
            [Page fetchPagesAsync];
            _history = nil;
            _bookmarks = nil;
            [HistoryItem clearCache];
            [Bookmark clearCache];
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
        [HistoryItem clearHistoryAsync];
}

-(IBAction)deleteRows:(UIBarButtonItem *)sender {
    int tabIndex = self.tabBar.selectedSegmentIndex;
    if (tabIndex == BOOKMARKS) {
        NSMutableArray *bookmarksToDelete = [NSMutableArray array];
        NSMutableArray *bookmarksMutable = [_bookmarks mutableCopy];
        for (NSIndexPath *indexPath in _selectedEditRows)
            [bookmarksToDelete addObject:[_bookmarks objectAtIndex:indexPath.row]];
        for (Bookmark *b in bookmarksToDelete)
            [bookmarksMutable removeObject:b];
        
        _bookmarks = [bookmarksMutable copy];
        [Bookmark deleteBookmarksAsync:bookmarksToDelete];
    }
    else if (tabIndex == SAVED_PAGES) {
        NSMutableArray *pagesToDelete = [NSMutableArray array];
        NSMutableArray *pagesMutable = [_pages mutableCopy];
        for (NSIndexPath *indexPath in _selectedEditRows)
            [pagesToDelete addObject:[_pages objectAtIndex:indexPath.row]];
        for (Page *p in pagesToDelete)
            [pagesMutable removeObject:p];
        _pages = [pagesMutable copy];
        [Page deletePagesAsync:pagesToDelete];
    }
        [self.tableView deleteRowsAtIndexPaths:[_selectedEditRows allObjects] withRowAnimation:UITableViewRowAnimationAutomatic];
        _selectedEditRows = [NSMutableSet set];
        self.deleteButton.enabled = NO;
        if ([self tableView:self.tableView numberOfRowsInSection:0] == 0) {
            [self edit:self.editButton];
            self.editButton.enabled = NO;
        }
    
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
            return _history.count;
            break;
        case BOOKMARKS:
            return _bookmarks.count;
            break;
        case SAVED_PAGES:
            return _pages.count;
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
            HistoryItem *item = [_history objectAtIndex:indexPath.row];
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
            Bookmark *bookmark = [_bookmarks objectAtIndex:indexPath.row];
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
            Page* page = [_pages objectAtIndex:indexPath.row];
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
                if (!_history)
                    _history = [HistoryItem history];
                HistoryItem *item = (HistoryItem*)[_history objectAtIndex:indexPath.row];
                [HistoryItem setHistoryIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectSavedPage:item];
            }
                break;
            case BOOKMARKS:
            {
                if (!_bookmarks)
                    _bookmarks = [Bookmark bookmarks];
                NSLog(@"bookmark selected");
                Bookmark *bookmark = (Bookmark*)[_bookmarks objectAtIndex:indexPath.row];
                [self.delegate savedPageController:self didSelectBookmarkWithURL:bookmark.url];
                
            }
                break;
            case SAVED_PAGES:
            {
                if (!_pages)
                    _pages = [Page pages];
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

-(void)didReceiveMemoryWarning {
    _history = nil;
    _bookmarks = nil;
    _pages = nil;
    [HistoryItem clearCache];
    [Bookmark clearCache];
    [Page clearCache];
}

-(void)viewWillDisappear:(BOOL)animated {
    _history = nil;
    _bookmarks = nil;
    _pages = nil;
    [HistoryItem clearCache];
    [Bookmark clearCache];
    [Page clearCache];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HISTORY_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BOOKMARKS_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAGES_NOTIFICATION_NAME object:nil];    
    [self setTableView:nil];
    [self setDoneButton:nil];
    [self setToolbar:nil];
    [self setDeleteButton:nil];
    [self setTabBar:nil];
    [self setEditButton:nil];
    [self setClearButton:nil];
	[self setRotationLockButton:nil];
    [super viewDidUnload];
}


- (IBAction)toggleRotationLock:(UIButton *)sender {
	BOOL rotationLocked = [defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    if (rotationLocked) {   //unlock rotation
        [defaults setBool:NO forKey:USER_PREF_ROTATION_LOCKED];
		[self.class attemptRotationToDeviceOrientation];
    } else {    //lock rotation to current orientation
        [defaults setBool:YES forKey:USER_PREF_ROTATION_LOCKED];
        [defaults setInteger:self.interfaceOrientation forKey:USER_PREF_ROTATION_ORIENTATION];
    }
    [defaults synchronize];
    [self setupRotationLockButton];
}

-(void)setupRotationLockButton {
    BOOL rotationLocked = [defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    if (rotationLocked) {
        [self.rotationLockButton setImage:[UIImage imageNamed:@"locked.png"] forState:UIControlStateNormal];
    } else {
        [self.rotationLockButton setImage:[UIImage imageNamed:@"unlocked.png"] forState:UIControlStateNormal];
    }
}

NSTimer *_savedLockHideTimer;

-(void) showRotationLockButton {
	self.rotationLockButton.hidden = NO;
	if (_savedLockHideTimer != nil)
		[_savedLockHideTimer invalidate];
	_savedLockHideTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideRotationLockButtonAfterTimer:) userInfo:nil repeats:NO];
}
-(void) hideRotationLockButtonAfterTimer:(NSTimer*)theTimer {
	[self.rotationLockButton setHidden:YES];
	_savedLockHideTimer = nil;
}

//iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    BOOL rotationLocked = [defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    NSInteger rotationOrientation = [defaults integerForKey:USER_PREF_ROTATION_ORIENTATION];
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
