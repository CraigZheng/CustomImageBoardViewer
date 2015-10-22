//
//  czzNavigationController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNavigationController.h"
#import "czzHomeViewController.h"
#import "czzNavigationManager.h"
#import "czzSettingsCentre.h"

@interface czzNavigationController () <UINavigationControllerDelegate, czzNavigationManagerDelegate>

@end

@implementation czzNavigationController
@synthesize notificationBannerViewController;
@synthesize onScreenImageManagerView;
@synthesize shortImageMangerController;
@synthesize progressView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NavigationManager.delegate = self;
    self.delegate = NavigationManager;

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
        onScreenImageManagerView = [czzOnScreenImageManagerViewController new];
        [onScreenImageManagerView stopAnimating]; //hide it at launch
    }
    if (!shortImageMangerController) {
        shortImageMangerController = [czzShortImageManagerCollectionViewController new];;
    }

}

#pragma mark - czzNavigationManagerDelegate
-(void)navigationManager:(czzNavigationManager *)manager wantsToPopToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self popToViewController:viewController animated:animated];
}

-(void)navigationManager:(czzNavigationManager *)manager wantsToPopViewControllerAnimated:(BOOL)animated {
    [self popViewControllerAnimated:animated];
}

-(void)navigationManager:(czzNavigationManager *)manager wantsToPushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [self pushViewController:viewController animated:animated];
}

- (void)navigationManager:(czzNavigationManager *)manager wantsToSetViewController:(NSArray *)viewControllers animated:(BOOL)animated {
    [self setViewControllers:viewControllers animated:animated];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"home_navigation_controller"];
}
@end
