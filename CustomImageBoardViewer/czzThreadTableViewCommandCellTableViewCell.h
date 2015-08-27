//
//  czzThreadTableViewCommandCellTableViewCell.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#define THREAD_TABLEVIEW_COMMAND_CELL_NIB_NAME @"czzThreadTableViewCommandCellTableViewCell"
#define THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER @"threadTableViewCommandCellTableViewCell"

#import <UIKit/UIKit.h>
#import "czzThreadViewCommandStatusCellViewController.h"

@interface czzThreadTableViewCommandCellTableViewCell : UITableViewCell
@property (nonatomic, assign) czzThreadViewCommandStatusCellViewType cellType;
@property (nonatomic, strong) czzThreadViewCommandStatusCellViewController *commandStatusViewController;

@end
