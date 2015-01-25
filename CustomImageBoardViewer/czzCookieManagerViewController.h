//
//  czzCookieManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#define COOKIE_MANAGER_VIEW_CONTROLLER_STORYBOARD_NAME @"CookieManager"

#import <UIKit/UIKit.h>

@interface czzCookieManagerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *cookieManagerTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *cookieManagerSegmentControl;
@property UIAlertView *useCookieAlertView;
@property UIAlertView *shareCookieAlertView;
@property UIAlertView *saveCookieAlertView;
@property UIAlertView *deleteCookieAlertView;
@property UIAlertView *addCookieAlertView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveCookieBarButtonItem;

- (IBAction)editAction:(id)sender;
- (IBAction)useCookieAction:(id)sender;
- (IBAction)shareCookieAction:(id)sender;
- (IBAction)saveCookieAction:(id)sender;
- (IBAction)deleteCookieAction:(id)sender;
- (IBAction)cookieManagerSegmentControlAction:(id)sender;
- (IBAction)addCookieAction:(id)sender;
@end
