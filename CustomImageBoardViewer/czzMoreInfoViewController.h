//
//  czzMoreInfoViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"
#import "GADBannerView.h"

#import "czzForum.h"

@interface czzMoreInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *headerTextWebView;
@property (strong, nonatomic) czzForum *forum;
@property GADBannerView *bannerView_;
@property (weak, nonatomic) IBOutlet UIView *barBackgroundView;
@property (weak, nonatomic) IBOutlet UINavigationItem *moreInfoNavItem;
@property (weak, nonatomic) IBOutlet UINavigationBar *moreInfoNaviBar;
- (IBAction)dismissAction:(id)sender;

- (IBAction)homePageAction:(id)sender;
@end
