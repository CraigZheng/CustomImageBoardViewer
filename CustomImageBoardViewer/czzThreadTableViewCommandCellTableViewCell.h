//
//  czzThreadTableViewCommandCellTableViewCell.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#define THREAD_TABLE_VIEW_CELL_NO_MORE_CELL_NIB_NAME @"czzNoMoreTableViewCell"
#define THREAD_TABLE_VIEW_CELL_LOADING_CELL_NIB_NAME @"czzLoadingTableViewCell"
#define THREAD_TABLE_VIEW_CELL_LOAD_MORE_CELL_NIB_NAME @"czzLoadMoreTableViewCell"

#define THREAD_TABLE_VIEW_CELL_NO_MORE_CELL_IDENTIFIER @"no_more_cell_identifier"
#define THREAD_TABLE_VIEW_CELL_LOADING_CELL_IDENTIFIER @"loading_cell_identifier"
#define THREAD_TABLE_VIEW_CELL_LOAD_MORE_CELL_IDENTIFIER @"load_more_cell_identifier"

#import <UIKit/UIKit.h>

@interface czzThreadTableViewCommandCellTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *commandLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
