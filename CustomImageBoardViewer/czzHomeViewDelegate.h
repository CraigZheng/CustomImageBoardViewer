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

@class czzHomeViewManager;


@interface czzHomeViewDelegate : NSObject <UITableViewDelegate, czzOnScreenImageManagerViewControllerDelegate>

@property (weak, nonatomic) czzHomeViewManager *homeViewManager;
@property (weak, nonatomic) czzThreadTableView *myTableView;

- (void)replyToThread:(czzThread *)thread inParentThread:(czzThread *)parentThread;
- (void)replyMainThread:(czzThread *)thread;
- (void)reportThread:(czzThread *)selectedThread inParentThread:(czzThread *)parentThread;
+ (instancetype)sharedInstance;
+ (instancetype)initWithViewManager:(czzHomeViewManager *)viewManager andTableView:(czzThreadTableView *)tableView;
@end
