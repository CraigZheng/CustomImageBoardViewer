//
//  czzThreadTableViewDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzOnScreenImageManagerViewController.h"
#import "czzThreadViewController.h"
#import "czzMenuEnabledTableViewCell.h"

@class czzHomeViewManager, czzThreadViewCommandStatusCellViewController;


@interface czzHomeTableViewManager : NSObject <UITableViewDelegate, UITableViewDataSource, czzOnScreenImageManagerViewControllerDelegate, czzMenuEnabledTableViewCellProtocol>

@property (weak, nonatomic) czzHomeViewManager *homeViewManager;
@property (weak, nonatomic) czzThreadTableView *homeTableView;
@property (nonatomic, assign) czzThreadViewCommandStatusCellViewController *commandStatusViewController;

- (void)reloadData;
@end
