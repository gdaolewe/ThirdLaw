//
//  IndexNavController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/12/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "IndexNavController.h"
#import "IndexData.h"
#import "TVC1.h"

@interface IndexNavController ()
@property IndexData *indexData;
@property BOOL dataLoaded;
@end

@implementation IndexNavController

@synthesize indexData = _indexData;
@synthesize dataLoaded = _dataLoaded;

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.dataLoaded = NO;
    self.indexData = [[IndexData alloc] init];
    [self.indexData loadHTML];
    self.dataLoaded = YES;
    //TVC1 *index = [self.storyboard instantiateViewControllerWithIdentifier:@"Index1"];
    //index.tableView.dataSource = self;
    //index.tableView.delegate = self;
    //[self pushViewController:index animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    return [self.indexData categoryCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Index level 1 celll";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index level 1 cell"];
    }
    
    cell.textLabel.text = [self.indexData categoryNameAtIndex:indexPath.row];
    
    return cell;
}



@end
