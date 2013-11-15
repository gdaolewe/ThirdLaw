//
//  SettingsViewController.m
//  ThirdLaw
//
//  Created by George Daole-Wellman on 11/14/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onDoneButton:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

@end
