//
//  czzNavigationController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNavigationController.h"
#import "czzHomeViewController.h"

@interface czzNavigationController () <UINavigationControllerDelegate>

@end

@implementation czzNavigationController
@synthesize notificationBannerViewController;
@synthesize onScreenImageManagerView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.delegate = self;
    //notification banner view
    notificationBannerViewController = (czzNotificationBannerViewController*) ([[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:nil] instantiateViewControllerWithIdentifier:@"notification_banner_view_controller"]);
    CGRect frame;
    frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height);
    notificationBannerViewController.view.frame = frame;
    notificationBannerViewController.homeViewController = self;
    [self.navigationBar addSubview:notificationBannerViewController.view];
    [self showNotificationBanner];
    
    
    //create on screen command if nil
    if (!onScreenImageManagerView)
    {
        onScreenImageManagerView = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateInitialViewController];
    }
    
}

-(void)showNotificationBanner {
    if ([notificationBannerViewController shouldShow]) {
        [notificationBannerViewController show];
        [self.view bringSubviewToFront:notificationBannerViewController.view];
    } else {
        [self hideNotificationBanner];
    }
}

-(void)hideNotificationBanner {
    [notificationBannerViewController hide];
//    notificationBannerViewController.view.hidden = YES;
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[czzHomeViewController class]]) {
        [self showNotificationBanner];
    } else {
        [self hideNotificationBanner];
    }
}
@end
