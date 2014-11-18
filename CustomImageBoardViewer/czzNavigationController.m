//
//  czzNavigationController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNavigationController.h"

@interface czzNavigationController ()

@end

@implementation czzNavigationController
@synthesize notificationBannerViewController;
@synthesize onScreenImageManagerView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //notification banner view
    notificationBannerViewController = [[czzNotificationBannerViewController alloc] initWithNibName:@"czzNotificationBannerViewController" bundle:[NSBundle mainBundle]];
    CGRect frame = notificationBannerViewController.view.frame;
    frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height);
    notificationBannerViewController.view.frame = frame;
    notificationBannerViewController.homeViewController = self;
    [self.navigationBar addSubview:notificationBannerViewController.view];
    
    
    //create on screen command if nil
    if (!onScreenImageManagerView)
    {
        onScreenImageManagerView = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateInitialViewController];
    }
    
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationBar bringSubviewToFront:notificationBannerViewController.view];
}

@end
