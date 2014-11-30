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
@synthesize shortImageMangerController;
@synthesize progressView;


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
    //progressview
    progressView = [[GSIndeterminateProgressView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height - 2, self.navigationBar.frame.size.width, 2)];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.navigationBar addSubview:progressView];
    
    
    //create on screen command if nil
    if (!onScreenImageManagerView)
    {
        onScreenImageManagerView = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateInitialViewController];
    }
    if (!shortImageMangerController) {
        shortImageMangerController = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"short_image_manager_view_controller"];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    progressView.progressTintColor = [UIColor colorWithRed:69/255. green:98/255. blue:157/255. alpha:1.0];
    //69	98	157 facebook blue
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {

}
@end
