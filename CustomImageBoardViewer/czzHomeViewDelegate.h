//
//  czzThreadTableViewDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzMenuEnabledTableViewCell.h"
#import "czzOnScreenImageManagerViewController.h"
#import "czzThreadViewController.h"

@class czzHomeViewManager;


@interface czzHomeViewDelegate : NSObject <UITableViewDelegate, czzMenuEnabledTableViewCellProtocol, czzOnScreenImageManagerViewControllerDelegate>

@property (weak, nonatomic) czzHomeViewManager *homeViewManager;
@property (weak, nonatomic) czzThreadTableView *myTableView;

+ (instancetype)sharedInstance;
+ (instancetype)initWithHomeViewManager:(czzHomeViewManager*)homeViewManager;
@end
