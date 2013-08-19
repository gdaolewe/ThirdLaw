//
//  SearchOptionsTVC.m
//  Lampshade
//
//  Created by George Daole-Wellman on 12/22/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "SearchOptionsTVC.h"

@interface SearchOptionsTVC ()

@end

@implementation SearchOptionsTVC

- (IBAction)done:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = (id<UITableViewDelegate>)(self.navigationController.presentingViewController);
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
