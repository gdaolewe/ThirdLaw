//
//  TVC1.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/12/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "TVC1.h"
#import "TVC2.h"
#import "IndexData.h"

@interface TVC1 () <UITableViewDelegate>
@end

@implementation TVC1

IndexData* _indexData;

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
    [_indexData loadHTML];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Index segue 1"] && [segue.destinationViewController respondsToSelector:@selector(categoryIndex)]) {
        TVC2 *dvc = segue.destinationViewController;
        dvc.categoryIndex = [self.tableView indexPathForSelectedRow].row;
    }
}
    
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    return [_indexData categoryCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Index level 1 celll";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Index level 1 cell"];
    }
    
    cell.textLabel.text = [_indexData categoryNameAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Index segue 1" sender:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
