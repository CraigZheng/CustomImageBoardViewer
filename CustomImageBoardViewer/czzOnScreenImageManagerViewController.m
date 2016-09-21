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
#import "czzImageViewerUtil.h"

#import <QuartzCore/QuartzCore.h>

#import "UIView+MGBadgeView.h"

@interface czzOnScreenImageManagerViewController () <czzImageDownloaderManagerDelegate, czzShortImageManagerCollectionViewControllerProtocol>
@property (assign, nonatomic) BOOL iconAnimating;
@property (assign, nonatomic) BOOL isShowingShortImageManagerController;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (assign, nonatomic) NSInteger unviewedImageCount;
@end

@implementation czzOnScreenImageManagerViewController
@synthesize mainIcon;
@synthesize iconAnimating;
@synthesize delegate;
@synthesize isShowingShortImageManagerController;

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
    [self.mainIconContainer.badgeView setPosition:MGBadgePositionTopRight];
    [self.mainIconContainer.badgeView setBadgeColor:[UIColor redColor]];

    // Add self to be a delegate of czzImageDownloaderManager
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([czzImageDownloaderManager sharedManager].isDownloading) {
        [self startAnimating];
    }
    self.mainIconContainer.badgeView.badgeValue = self.unviewedImageCount;
}

- (IBAction)tapOnImageManagerIconAction:(id)sender {
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

#pragma mark - Prepare for segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[czzShortImageManagerCollectionViewController class]]) {
        [(czzShortImageManagerCollectionViewController *)segue.destinationViewController setDelegate:self];
        // Reset unviewed images value.
        self.unviewedImageCount =
        self.mainIconContainer.badgeView.badgeValue = 0;
    }
}

#pragma mark - czzImageDownloaderDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (!downloader.isThumbnail) {
        if (success) {
            if (![settingCentre userDefShouldAutoOpenImage] &&
                !self.isShowingShortImageManagerController) {
                // Badge value needs to be reset as well.
                self.mainIconContainer.badgeView.badgeValue = self.unviewedImageCount;
            } else {
                self.unviewedImageCount = self.mainIconContainer.badgeView.badgeValue = 0;
            }
        }
        if (manager.imageDownloaders.count <= 0)
        {
            [self stopAnimating];
        }
    }
}

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

#pragma mark - czzShortImageManagerCollectionViewController

- (void)shortImageManager:(czzShortImageManagerCollectionViewController *)manager selectedImageWithIndex:(NSInteger)index inImages:(NSArray *)imageSource {
    self.imageViewerUtil = [czzImageViewerUtil new];
    [self.imageViewerUtil showPhotos:imageSource withIndex:index];
}

#pragma mark - Getters && Setters

- (BOOL)isShowingShortImageManagerController {
    // If the topViewController is a czzShortImageManagerCollectionViewController, return YES.
    if ([[UIApplication topViewController] isMemberOfClass:[czzShortImageManagerCollectionViewController class]]) {
        return YES;
    }
    return NO;
}

- (NSInteger)unviewedImageCount {
    NSInteger count = [czzImageDownloaderManager sharedManager].unviewedImageCount;
    return count;
}

- (void)setUnviewedImageCount:(NSInteger)unviewedImageCount {
    [czzImageDownloaderManager sharedManager].unviewedImageCount = unviewedImageCount;
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateInitialViewController];
}
@end
