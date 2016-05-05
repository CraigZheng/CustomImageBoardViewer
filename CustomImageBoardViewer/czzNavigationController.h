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
#import "czzShortImageManagerCollectionViewController.h"
#import "GSIndeterminateProgressView.h"
#import "SlideNavigationController.h"

@interface czzNavigationController : SlideNavigationController
@property (strong) czzNotificationBannerViewController *notificationBannerViewController;
@property (nonatomic, strong) UINavigationController *leftViewController;

@end
