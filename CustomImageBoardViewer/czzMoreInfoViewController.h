//
//  czzMoreInfoViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzForum.h"

@interface czzMoreInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *headerTextWebView;
@property (weak, nonatomic) IBOutlet UIWebView *coverImageWebView;
@property (strong, nonatomic) czzForum *forum;
@property UIView *bannerView_; // TODO: This ad banner view is not in used anymore, we could remove it later.
@property (weak, nonatomic) IBOutlet UINavigationItem *moreInfoNavItem;
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
- (IBAction)dismissAction:(id)sender;

@end
