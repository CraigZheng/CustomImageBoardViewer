//
//  czzThreadTableViewDataSource.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadTableView.h"
#import "czzHomeViewDelegate.h"

@class czzHomeViewManager;
@interface czzHomeTableViewDataSource : NSObject <UITableViewDataSource, UITableViewDelegate>
@property czzHomeViewManager *homeViewManager;
@property (weak, nonatomic) czzThreadTableView *myTableView;
@property (weak, nonatomic) czzHomeViewDelegate *tableViewDelegate;

+(instancetype)initWithViewManager:(czzHomeViewManager *)viewManager andTableView:(czzThreadTableView *)tableView;
@end
