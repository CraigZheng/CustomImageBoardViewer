//
//  czzNavigationController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNavigationController.h"
#import "czzHomeViewController.h"
#import "czzNavigationViewModelManager.h"
#import "czzSettingsCentre.h"

@interface czzNavigationController () <UINavigationControllerDelegate, czzNavigationViewModelManagerDelegate>

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
        onScreenImageManagerView = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateInitialViewController];
        [onScreenImageManagerView stopAnimating]; //hide it at launch
    }
    if (!shortImageMangerController) {
        shortImageMangerController = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:SHORT_IMAGE_MANAGER_VIEW_CONTROLLER];
    }

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationBar.barTintColor = [settingCentre barTintColour];
    //252	103	61
    self.navigationBar.tintColor = [settingCentre tintColour];
    
    //consistent look for tool bar and label
    [self.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : self.navigationBar.tintColor}];
    self.toolbar.barTintColor = self.navigationBar.barTintColor;
    self.toolbar.tintColor = self.navigationBar.tintColor;
}

#pragma mark - czzNavigationViewModelManagerDelegate
-(void)viewModelManager:(czzNavigationViewModelManager *)manager wantsToPopToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self popToViewController:viewController animated:animated];
}

-(void)viewModelManager:(czzNavigationViewModelManager *)manager wantsToPopViewControllerAnimated:(BOOL)animated {
    [self popViewControllerAnimated:animated];
}

-(void)viewModelManager:(czzNavigationViewModelManager *)manager wantsToPushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [self pushViewController:viewController animated:animated];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"home_navigation_controller"];
}
@end
