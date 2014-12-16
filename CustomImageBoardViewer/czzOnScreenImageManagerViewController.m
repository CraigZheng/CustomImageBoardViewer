//
//  czzOnScreenImageManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzOnScreenImageManagerViewController.h"
#import "czzNavigationController.h"
#import "UIImage+animatedGIF.h"
#import "czzImageDownloader.h"
#import "czzImageCentre.h"

@interface czzOnScreenImageManagerViewController () <czzImageCentreProtocol, czzShortImageManagerCollectionViewControllerProtocol>
@property BOOL iconAnimating;
@property BOOL isShowingShortImageManagerController;
@property czzImageCentre *imageCentre;
@property (nonatomic) czzShortImageManagerCollectionViewController *shortImageManagerCollectionViewController;
@end

@implementation czzOnScreenImageManagerViewController
@synthesize mainIcon;
@synthesize iconAnimating;
@synthesize imageCentre;
@synthesize delegate;
@synthesize isShowingShortImageManagerController;
@synthesize shortImageManagerCollectionViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, mainIcon.frame.size.width, mainIcon.frame.size.height) cornerRadius:MAX(mainIcon.frame.size.width, mainIcon.frame.size.height)];
    
    circle.path = circularPath.CGPath;
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    mainIcon.layer.mask=circle;
    
    iconAnimating = NO;
    
    //image centre
    imageCentre = [czzImageCentre sharedInstance];
    imageCentre.delegate = self;
}

-(czzShortImageManagerCollectionViewController *)shortImageManagerCollectionViewController {
    //grab and return the short image manager from my own navigation controller
    shortImageManagerCollectionViewController = [(czzNavigationController*)self.parentViewController.navigationController shortImageMangerController];
    if (!shortImageManagerCollectionViewController.delegate)
        shortImageManagerCollectionViewController.delegate = self;
    return shortImageManagerCollectionViewController;
}

- (IBAction)tapOnImageManagerIconAction:(id)sender {
    [self.shortImageManagerCollectionViewController show];
}

-(void)startAnimating {
    iconAnimating = YES;
    NSURL *acURL = [[NSBundle mainBundle] URLForResource:@"running_ac" withExtension:@"gif"];
    mainIcon.image = [UIImage animatedImageWithAnimatedGIFURL:acURL];
    self.view.hidden = NO;
}

-(void)stopAnimating {
    iconAnimating = NO;
    mainIcon.image = [UIImage imageNamed:@"Icon.png"];
    self.view.hidden = YES;
}

#pragma mark - czzImageCentreDelegate
-(void)imageCentreDownloadFinished:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader wasSuccessful:(BOOL)success {
    if (!downloader.isThumbnail
        &&
        delegate
        && [delegate respondsToSelector:@selector(onScreenImageManagerDownloadFinished:imagePath:wasSuccessful:)]
        && !self.shortImageManagerCollectionViewController.isShowing
        ) {
        [delegate onScreenImageManagerDownloadFinished:self imagePath:downloader.savePath wasSuccessful:success];
    }
    if (imageCentre.currentImageDownloaders.count <= 0)
    {
        [self stopAnimating];
    }
}

-(void)imageCentreDownloadUpdated:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader progress:(CGFloat)progress {
    if (self.shortImageManagerCollectionViewController && self.shortImageManagerCollectionViewController.isShowing) {
        [self.shortImageManagerCollectionViewController updateProgressForDownloader:downloader];
    }
}

-(void)imageCentreDownloadStarted:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader {
    if (!downloader.isThumbnail && !iconAnimating)
        [self startAnimating];
}

#pragma mark - czzShortImageManagerCollectionViewControllerDelegate
-(void)userTappedOnImageWithPath:(NSString *)imagePath {
    DLog(@"%@", NSStringFromSelector(_cmd));
}

@end
