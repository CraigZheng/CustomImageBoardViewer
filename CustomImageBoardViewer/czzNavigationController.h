//
//  czzNavigationController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzNotificationBannerViewController.h"
#import "czzOnScreenImageManagerViewController.h"

@interface czzNavigationController : UINavigationController
@property czzNotificationBannerViewController *notificationBannerViewController;
@property czzOnScreenImageManagerViewController *onScreenImageManagerView;

-(void)showNotificationBanner;
-(void)hideNotificationBanner;
@end
