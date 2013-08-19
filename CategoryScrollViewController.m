//
//  CategoryScrollViewController.m
//  TVTropes
//
//  Created by George Daole-Wellman on 11/10/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "CategoryScrollViewController.h"
#import "IndexData.h"
#import "CategoryTVC.h"

@interface CategoryScrollViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property int page;
@property BOOL pageControlUsed;
@property BOOL rotating;
@property IndexData *categoryData;

- (IBAction)changePage:(UIPageControl *)sender;
@end

@implementation CategoryScrollViewController
@synthesize pageControl = _pageControl;
@synthesize scrollView = _scrollView;
@synthesize page = _page;
@synthesize pageControlUsed = _pageControlUsed;
@synthesize rotating = _rotating;
@synthesize categoryData = _categoryData;

- (IBAction)changePage:(UIPageControl *)sender {
    self.page = sender.currentPage;
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * self.page;
    frame.origin.y = 0;
    
    UIViewController *oldViewController = [self.childViewControllers objectAtIndex:self.page];
    UIViewController *newViewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    [oldViewController viewWillDisappear:YES];
    [newViewController viewWillAppear:YES];
    
    [self.scrollView scrollRectToVisible:frame animated:YES];
    [self.pageControl updateCurrentPageDisplay];
    self.pageControlUsed = YES;
}

-(BOOL) automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers {
    return NO;
}
-(void) viewDidLoad {
    [super viewDidLoad];
        
    
}
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    if (viewController.view.superview != nil)
        [viewController viewDidAppear:animated];
}
-(void) viewWillDisappear:(BOOL)animated {
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    if (viewController.view.superview != nil)
        [viewController viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}
-(void) viewDidDisappear:(BOOL)animated {
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    if (viewController.view.superview != nil)
        [viewController viewDidDisappear:animated];
    [super viewDidDisappear:animated];
}
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSUInteger i=0; i<[self.childViewControllers count]; i++)
        [self loadScrollViewWithPage:i];
    self.pageControl.currentPage =0;
    self.page = 0;
    [self.pageControl setNumberOfPages:[self.childViewControllers count]];
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    if (viewController.view.superview != nil)
        [viewController viewWillAppear:animated];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.childViewControllers count], self.scrollView.frame.size.height);
}
-(void) loadScrollViewWithPage:(int)page {
    if (page < 0)
        return;
    if (page >= [self.childViewControllers count])
        return;
    
    UIViewController *controller = [self.childViewControllers objectAtIndex:page];
    if (controller == nil)
        return;
    if (controller.view.superview == nil) {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.scrollView addSubview:controller.view];
    }
}
-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.pageControlUsed = NO;
}
-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.pageControlUsed = NO;
}
-(void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    UIViewController *oldViewController = [self.childViewControllers objectAtIndex:self.page];
    UIViewController *newViewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    [oldViewController viewDidDisappear:YES];
    [newViewController viewDidAppear:YES];
    self.page = self.pageControl.currentPage;

}
-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.pageControlUsed || self.rotating)
        return;
    
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (self.pageControl.currentPage != page) {
        UIViewController *oldViewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
        UIViewController *newViewController = [self.childViewControllers objectAtIndex:page];
        [oldViewController viewWillDisappear:YES];
        [newViewController viewWillAppear:YES];
        self.pageControl.currentPage = page;
        [oldViewController viewDidDisappear:YES];
        [newViewController viewDidAppear:YES];
        self.page = page;
        
        
    }
    
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.rotating = YES;
}
-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    [viewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.childViewControllers count], self.scrollView.frame.size.height);
    NSUInteger page = 0;
    for (viewController in self.childViewControllers) {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = frame.size.width * self.page;
        frame.origin.y = 0;
        viewController.view.frame = frame;
        page++;
    }
    
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * self.page;
    frame.origin.y = 0;
    [self.scrollView scrollRectToVisible:frame animated:NO];
}
-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.rotating = NO;
    UIViewController *viewController = [self.childViewControllers objectAtIndex:self.pageControl.currentPage];
    [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

@end
