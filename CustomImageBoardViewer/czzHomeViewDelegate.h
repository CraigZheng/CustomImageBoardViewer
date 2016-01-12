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

@class czzHomeViewManager;


@interface czzHomeViewDelegate : NSObject <UITableViewDelegate, czzOnScreenImageManagerViewControllerDelegate, czzMenuEnabledTableViewCellProtocol>

@property (weak, nonatomic) czzHomeViewManager *homeViewManager;
@property (weak, nonatomic) czzThreadTableView *myTableView;
@property (nonatomic, strong) NSMutableDictionary *cachedHorizontalHeights;
@property (nonatomic, strong) NSMutableDictionary *cachedVerticalHeights;

- (void)replyToThread:(czzThread *)thread inParentThread:(czzThread *)parentThread;
- (void)replyMainThread:(czzThread *)thread;
- (void)reportThread:(czzThread *)selectedThread inParentThread:(czzThread *)parentThread;
+ (instancetype)sharedInstance;
+ (instancetype)initWithViewManager:(czzHomeViewManager *)viewManager andTableView:(czzThreadTableView *)tableView;
@end
