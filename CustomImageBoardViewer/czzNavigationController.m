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
#import "czzFavouriteManagerViewController.h"
#import "czzForumsViewController.h"
#import "UINavigationController+Util.h"
#import "CustomImageBoardViewer-Swift.h"

@interface czzNavigationController () <UINavigationControllerDelegate, czzNavigationManagerDelegate>
@end

@implementation czzNavigationController
@synthesize notificationBannerViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NavigationManager.delegate = self;
    self.delegate = NavigationManager;
    [SlideNavigationController sharedInstance].leftMenu = self.leftViewController;
    [SlideNavigationController sharedInstance].enableSwipeGesture = YES;
    [SlideNavigationController sharedInstance].panGestureSideOffset = 0;
    [self applyAppearance];

    //notification banner view
    notificationBannerViewController = [czzNotificationBannerViewController new];
    CGRect frame;
    frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height);
    notificationBannerViewController.view.frame = frame;
    notificationBannerViewController.homeViewController = self;
}

#pragma mark - Getters

- (UINavigationController *)leftViewController {
    if (!_leftViewController) {
        czzForumsViewController *forumsViewController = [[czzForumsViewController alloc] initWithStyle:UITableViewStylePlain];
        CustomAppearanceNavigationController *navigationController = [[CustomAppearanceNavigationController alloc] initWithRootViewController:forumsViewController];
        navigationController.definesPresentationContext = YES;
        navigationController.restorationIdentifier = @"left_side_view_controller";
        navigationController.toolbarHidden = NO;
        navigationController.edgesForExtendedLayout = UIRectEdgeNone;
        _leftViewController = navigationController;
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

- (void)showWatchList {
    czzFavouriteManagerViewController *favouriteViewController = [czzFavouriteManagerViewController new];
    if ([favouriteViewController isKindOfClass:[czzFavouriteManagerViewController class]]) {
        favouriteViewController.launchToIndex = watchIndex;
        [self pushViewController:favouriteViewController animated:YES];
    }
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"home_navigation_controller"];
}
@end
