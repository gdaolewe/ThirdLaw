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

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"did select row");
	switch (indexPath.row) {
		case LeftDrawerHomePage: {
			UINavigationController *nav = (UINavigationController*)self.mm_drawerController.centerViewController;
			PageViewController *pageVC = [nav.childViewControllers objectAtIndex:0];
			[pageVC loadHomePage];
			[self.mm_drawerController closeDrawerAnimated:YES completion:nil];
		}
			break;
		case LeftDrawerRandomPage: {
			UINavigationController *nav = (UINavigationController*)self.mm_drawerController.centerViewController;
			PageViewController *pageVC = [nav.childViewControllers objectAtIndex:0];
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
			UINavigationController *nav = (UINavigationController*)self.mm_drawerController.centerViewController;
			UIViewController *settings = [self.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
			[self.mm_drawerController closeDrawerAnimated:YES completion:nil];
			[nav presentModalViewController:settings animated:YES];
		}
			break;
	}
}

@end
