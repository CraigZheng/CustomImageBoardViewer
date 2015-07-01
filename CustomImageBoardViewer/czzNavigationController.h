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

@interface czzNavigationController : UINavigationController
@property (strong) czzNotificationBannerViewController *notificationBannerViewController;
@property (strong) czzOnScreenImageManagerViewController *onScreenImageManagerView;
@property (strong) czzShortImageManagerCollectionViewController *shortImageMangerController;
@property (strong) GSIndeterminateProgressView *progressView;

@end
