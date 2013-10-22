//
//  HomeViewController.m
//  ThirdLaw
//
//  Created by George Daole-Wellman on 10/6/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "HomeViewController.h"
#import "PageViewController.h"

@interface HomeViewController () 

@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSLog(@"HomeToSaved segue");
	if ([segue.identifier isEqualToString:@"HomeToSaved"])
		((SavedPagesController*)segue.destinationViewController).delegate = self;
}

#pragma mark - SavedPagesDelegate
-(void)savedPageController:(id)controller didSelectSavedPage:(id<GenericSavedPage>)page {
	PageViewController *pageVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
	[pageVC savedPageController:controller didSelectSavedPage:page];
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	[self.navigationController pushViewController:pageVC animated:YES];
}

-(void)savedPageController:(id)controller didSelectBookmarkWithURL:(NSString *)url {
	PageViewController *pageVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Page"];
	[pageVC savedPageController:controller didSelectBookmarkWithURL:url];
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	[self.navigationController pushViewController:pageVC animated:YES];
}

@end
