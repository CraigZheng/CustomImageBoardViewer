//
//  czzAddForumTableViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 24/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@class czzAddForumTableViewController;
@protocol czzAddForumTableViewControllerProtocol <NSObject>
- (void)addForumTableViewControllerDidDismissed:(czzAddForumTableViewController *)viewController;
@end

@interface czzAddForumTableViewController : UITableViewController

@property id<czzAddForumTableViewControllerProtocol> delegate;

@end
