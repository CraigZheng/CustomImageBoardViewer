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

- (IBAction)reloadAction:(id)sender;
@end
