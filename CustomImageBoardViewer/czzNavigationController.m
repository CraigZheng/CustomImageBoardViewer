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
}

#pragma mark - Getters

- (UINavigationController *)leftViewController {
    if (!_leftViewController) {
        _leftViewController = [[UIStoryboard storyboardWithName:@"ForumSelector" bundle:nil] instantiateInitialViewController];
    }
    return _leftViewController;
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

- (void)showFavourite {
    [self performSegueWithIdentifier:@"FavouriteManager" sender:nil];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"home_navigation_controller"];
}
@end
