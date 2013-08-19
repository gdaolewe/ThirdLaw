//
//  PageViewControllerNative.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/17/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "PageViewControllerNative.h"
#import "PageData.h"
#import "TTTAttributedLabel.h"
#import "ExternalWebViewController.h"

@interface PageViewControllerNative () <TTTAttributedLabelDelegate>
@property (strong, nonatomic) IBOutlet UILabel *pageTitle;
@property (strong, nonatomic) IBOutlet UIImageView *pageImage;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet TTTAttributedLabel* imageCaption;
@property (strong, nonatomic) IBOutlet TTTAttributedLabel* pageQuote;
@property (strong, nonatomic) IBOutlet TTTAttributedLabel* pageLede;

@end

@implementation PageViewControllerNative
@synthesize pageTitle;
@synthesize pageImage;
@synthesize scrollView;
@synthesize imageCaption;
@synthesize pageQuote;
@synthesize pageLede;

PageData* _pageData;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _pageData = [PageData sharedPageDataWithURL:[NSURL URLWithString:@"http://tvtropes.org/pmwiki/pmwiki.php/Series/Firefly"]];
    
    UIImage* img = [UIImage imageWithData:[NSData dataWithContentsOfURL:[_pageData pageImageURL]]];
    self.pageImage.image = img;
    
    self.pageTitle.text = [_pageData pageTitle];
    
    [_pageData pageImageCaptionForLabel:self.imageCaption];
    [self.imageCaption sizeToFit];
    self.imageCaption.delegate = self;
    
    [_pageData pageQuoteForLabel:self.pageQuote];
    self.pageQuote.delegate = self;
    CGRect frame = self.pageQuote.frame;
    frame.origin.y = self.imageCaption.frame.origin.y + self.imageCaption.frame.size.height;
    self.pageQuote.frame = frame;
    
    [_pageData pageLedeForLabel:self.pageLede];
    self.pageLede.delegate = self;
    frame = self.pageLede.frame;
    frame.origin.y = self.pageQuote.frame.origin.y + self.pageQuote.frame.size.height;
    self.pageLede.frame = frame;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.pageLede.frame.origin.y + self.pageLede.frame.size.height + 60);
}

- (void)viewDidUnload
{
    [self setPageImage:nil];
    [self setPageTitle:nil];
    [self setScrollView:nil];
    [self setImageCaption:nil];
    [self setPageQuote:nil];
    [self setPageLede:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    ExternalWebViewController* externalWebViewC = [self.storyboard instantiateViewControllerWithIdentifier:@"External WebView"];
    externalWebViewC.url = url;
    [self.navigationController pushViewController:externalWebViewC animated:YES];
}

@end
