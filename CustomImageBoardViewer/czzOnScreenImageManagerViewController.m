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
#import "czzImageDownloaderManager.h"
#import "czzImageCacheManager.h"
#import "czzSettingsCentre.h"

#import <QuartzCore/QuartzCore.h>

#import "UIView+MGBadgeView.h"
#import "KLCPopup.h"

@interface czzOnScreenImageManagerViewController () <czzImageDownloaderManagerDelegate, czzShortImageManagerCollectionViewControllerProtocol>
@property (assign, nonatomic) BOOL iconAnimating;
@property (assign, nonatomic) BOOL isShowingShortImageManagerController;
@property (nonatomic) czzShortImageManagerCollectionViewController *shortImageManagerCollectionViewController;
@end

@implementation czzOnScreenImageManagerViewController
@synthesize mainIcon;
@synthesize iconAnimating;
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
    //round image
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    mainIcon.layer.mask=circle;
    //shadow
    
    iconAnimating = NO;
    
    //badge view
    [self.view.badgeView setPosition:MGBadgePositionTopRight];
    [self.view.badgeView setBadgeColor:[UIColor redColor]];

    // Add self to be a delegate of czzImageDownloaderManager
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
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

#pragma mark - czzImageDownloaderDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success && !downloader.isThumbnail) {
        if (![settingCentre userDefShouldAutoOpenImage]) {
            [self.view.badgeView setBadgeValue:self.view.badgeView.badgeValue + 1];
        }
    }
    if (manager.imageDownloaders.count <= 0)
    {
        [self stopAnimating];
    }
}

#warning MOVE THIS PART TO czzShortImageManagerViewController.
//-(void)imageCentreDownloadUpdated:(czzImageCacheManager *)imgCentre downloader:(czzImageDownloader *)downloader progress:(CGFloat)progress {
//    if (self.shortImageManagerCollectionViewController.isShowing) {
//        [self.shortImageManagerCollectionViewController reloadTableView];
//    }
//}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedStarted:(czzImageDownloader *)downloader imageName:(NSString *)imageName {
    if (!downloader.isThumbnail && !iconAnimating)
        [self startAnimating];
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedStopped:(czzImageDownloader *)downloader imageName:(NSString *)imageName {
    if (manager.imageDownloaders.count <= 0)
    {
        [self stopAnimating];
    }
}

#pragma mark - czzShortImageManagerCollectionViewControllerDelegate
-(void)userTappedOnImageWithPath:(NSString *)imagePath {
    [KLCPopup dismissAllPopups];
    if (delegate && [delegate respondsToSelector:@selector(onScreenImageManagerSelectedImage:)])
    {
        [delegate onScreenImageManagerSelectedImage:imagePath];
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateInitialViewController];
}
@end
