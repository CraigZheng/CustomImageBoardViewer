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

@interface czzOnScreenImageManagerViewController () <czzImageCentreProtocol>
@property BOOL iconAnimating;
@property czzImageCentre *imageCentre;
@end

@implementation czzOnScreenImageManagerViewController
@synthesize mainIcon;
@synthesize iconAnimating;
@synthesize imageCentre;
@synthesize delegate;

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

- (IBAction)tapOnImageManagerIconAction:(id)sender {
    DLog(@"%@", NSStringFromSelector(_cmd));
    
    [[(czzNavigationController*)self.parentViewController.navigationController shortImageMangerController] show];
    [self startAnimating];
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

#pragma mark - czzImageCentreDelegate
-(void)imageCentreDownloadFinished:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader wasSuccessful:(BOOL)success {
    if (!downloader.isThumbnail && delegate && [delegate respondsToSelector:@selector(onScreenImageManagerDownloadFinished:imagePath:wasSuccessful:)]) {
        [delegate onScreenImageManagerDownloadFinished:self imagePath:downloader.savePath wasSuccessful:success];
    }
}

-(void)imageCentreDownloadUpdated:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader progress:(CGFloat)progress {
    DLog(@"image downloader updated, progress: %.1f", progress);
}
@end
