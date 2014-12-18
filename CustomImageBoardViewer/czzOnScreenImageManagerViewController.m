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
#import "czzSettingsCentre.h"

#import "UIView+MGBadgeView.h"
#import "KLCPopup.h"

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
@synthesize downloadedImages;

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
    
    //badge view
    [self.view.badgeView setPosition:MGBadgePositionTopRight];
    [self.view.badgeView setBadgeColor:[UIColor redColor]];

}

-(czzShortImageManagerCollectionViewController *)shortImageManagerCollectionViewController {
    //grab and return the short image manager from my own navigation controller
    shortImageManagerCollectionViewController = [(czzNavigationController*)self.parentViewController.navigationController shortImageMangerController];
    shortImageManagerCollectionViewController.hostViewController = self.parentViewController;
    if (!shortImageManagerCollectionViewController.delegate)
        shortImageManagerCollectionViewController.delegate = self;
    return shortImageManagerCollectionViewController;
}

- (IBAction)tapOnImageManagerIconAction:(id)sender {
    [self.shortImageManagerCollectionViewController show];
    //reset badge value
    self.view.badgeView.badgeValue = 0;
}

-(void)startAnimating {
    iconAnimating = YES;
    NSURL *acURL = [[NSBundle mainBundle] URLForResource:@"running_ac" withExtension:@"gif"];
    mainIcon.image = [UIImage animatedImageWithAnimatedGIFURL:acURL];
}

-(void)stopAnimating {
    iconAnimating = NO;
    mainIcon.image = [UIImage imageNamed:@"Icon.png"];
}

-(NSMutableArray *)downloadedImages {
    return self.shortImageManagerCollectionViewController.downloadedImages;
}

#pragma mark - czzImageCentreDelegate
-(void)imageCentreDownloadFinished:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader wasSuccessful:(BOOL)success {
    if (success && !downloader.isThumbnail) {
        if (delegate
            && [delegate respondsToSelector:@selector(onScreenImageManagerDownloadFinished:imagePath:wasSuccessful:)]
            && !self.shortImageManagerCollectionViewController.isShowing
            ) {
            [delegate onScreenImageManagerDownloadFinished:self imagePath:downloader.savePath wasSuccessful:success];
            if (![settingCentre userDefShouldAutoOpenImage]) {
                [self.view.badgeView setBadgeValue:self.view.badgeView.badgeValue + 1];
            }
        }
        [self.shortImageManagerCollectionViewController imageDownloaded:downloader.savePath];
    }
    if (imageCentre.currentImageDownloaders.count <= 0)
    {
        [self stopAnimating];
    }
}

-(void)imageCentreDownloadUpdated:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader progress:(CGFloat)progress {
    if (self.shortImageManagerCollectionViewController.isShowing) {
        [self.shortImageManagerCollectionViewController updateProgressForDownloader:downloader];
    }
}

-(void)imageCentreDownloadStarted:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader {
    if (!downloader.isThumbnail && !iconAnimating)
        [self startAnimating];
}

#pragma mark - czzShortImageManagerCollectionViewControllerDelegate
-(void)userTappedOnImageWithPath:(NSString *)imagePath {
    [KLCPopup dismissAllPopups];
    if (delegate && [delegate respondsToSelector:@selector(onScreenImageManagerSelectedImage:)])
    {
        [delegate onScreenImageManagerSelectedImage:imagePath];
    }
}

@end
