//
//  czzThreadViewCommandStatusCellViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#define THREAD_TABLEVIEW_COMMAND_CELL_NIB_NAME @"czzThreadTableViewCommandCellTableViewCell"
#define THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER @"threadTableViewCommandCellTableViewCell"

typedef NS_ENUM(NSInteger, czzThreadViewCommandStatusCellViewType) {
    czzThreadViewCommandStatusCellViewTypeLoadMore = 0,
    czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore = 1,
    czzThreadViewCommandStatusCellViewTypeNoMore = 2,
    czzThreadViewCommandStatusCellViewTypeLoading = 3
};

@class czzHomeViewManager;
@interface czzThreadViewCommandStatusCellViewController : UIViewController
@property (nonatomic, strong) czzHomeViewManager *homeViewManager;
@property (nonatomic, assign) czzThreadViewCommandStatusCellViewType cellType;
@end
