//
//  CategoryViewController.m
//  TVTropes
//
//  Created by George Daole-Wellman on 10/31/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "CategoryViewController.h"
#import "TFHpple.h"
#import "Parser.h"
#import "Contributor.h"

@interface CategoryViewController () <UIPageViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *categoryScrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageController;

@end

@implementation CategoryViewController
@synthesize categoryScrollView;
@synthesize pageController;

-(BOOL) automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers {
    return NO;
}
/*-(void) loadStuff {
    NSURL *stuffURL = [NSURL URLWithString:@"http://tvtropes.org/pmwiki/pmwiki.php/Main/HomePage"];
    NSData *stuffHTMLData = [NSData dataWithContentsOfURL:stuffURL];
    TFHpple *stuffParser = [TFHpple hppleWithHTMLData:stuffHTMLData];
    NSString *xpathQuery = @"//div[@id='wikileftpage']//li[@class='plus']/a";
    //NSArray *stuffNodes = [stuffParser searchWithXPathQuery:xpathQuery];
    //for (TFHppleElement *e in stuffNodes) {
    //    NSLog(@"%@\n%@", [[e firstChild] content],[e objectForKey:@"href"]);
    //}
    
}*/


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //[self loadStuff];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
    [self setPageController:nil];
    [self setCategoryScrollView:nil];
    [super viewDidUnload];
}
@end
