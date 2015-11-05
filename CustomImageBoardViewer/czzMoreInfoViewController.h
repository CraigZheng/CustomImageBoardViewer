//
//  czzMoreInfoViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@import GoogleMobileAds;

#import "IIViewDeckController.h"
#import "czzForum.h"

@interface czzMoreInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *headerTextWebView;
@property (strong, nonatomic) czzForum *forum;
@property GADBannerView *bannerView_;
@property (weak, nonatomic) IBOutlet UINavigationItem *moreInfoNavItem;
- (IBAction)dismissAction:(id)sender;

- (IBAction)homePageAction:(id)sender;
@end
