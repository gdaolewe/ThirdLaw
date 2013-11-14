//
//  LeftDrawerTVC.m
//  ThirdLaw
//
//  Created by George Daole-Wellman on 11/9/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "LeftDrawerTVC.h"
#import <UIViewController+MMDrawerController.h>
#import "PageViewController.h"
#import "IndexTableViewController.h"

@interface LeftDrawerTVC ()

typedef enum {
	LeftDrawerCurrentPage,
	LeftDrawerHomePage,
	LeftDrawerRandomPage,
	LeftDrawerIndex,
	LeftDrawerSettings
}LeftDrawerCell;

@end

@implementation LeftDrawerTVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier;
    switch(indexPath.row) {
		case LeftDrawerCurrentPage: {
			CellIdentifier = @"CurrentPage";
		}
			break;
		case LeftDrawerHomePage: {
			CellIdentifier = @"HomePage";
		}
			break;
		case LeftDrawerRandomPage: {
			CellIdentifier = @"RandomPage";
		}
			break;
		case LeftDrawerIndex: {
			CellIdentifier = @"Index";
		}
			break;
		case LeftDrawerSettings: {
			CellIdentifier = @"Settings";
		}
			break;
	}
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    return cell;
}*/

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"did select row");
	switch (indexPath.row) {
		case LeftDrawerCurrentPage: {
			
		}
			break;
		case LeftDrawerHomePage: {
			UINavigationController *centerVC = (UINavigationController*)self.mm_drawerController.centerViewController;
			PageViewController *pageVC = [centerVC.childViewControllers objectAtIndex:0];
			[pageVC loadHomePage];
			[self.mm_drawerController closeDrawerAnimated:YES completion:nil];
		}
			break;
		case LeftDrawerRandomPage: {
			UINavigationController *centerVC = (UINavigationController*)self.mm_drawerController.centerViewController;
			PageViewController *pageVC = [centerVC.childViewControllers objectAtIndex:0];
			[pageVC loadRandomURL];
			[self.mm_drawerController closeDrawerAnimated:YES completion:nil];
		}
			break;
		case LeftDrawerIndex: {
			UINavigationController *nav = (UINavigationController*)self.mm_drawerController.centerViewController;
			IndexTableViewController *index = [self.storyboard instantiateViewControllerWithIdentifier:@"Index"];
			[self.mm_drawerController closeDrawerAnimated:YES completion:nil];
			[nav pushViewController:index animated:YES];
		}
			break;
		case LeftDrawerSettings: {
			
		}
			break;
	}
}



/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
