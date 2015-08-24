//
//  czzThreadTableView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzOnScreenCommandViewController.h"

typedef enum {
    czzThreadTableViewLastCommandCellTypeLoadMore = 0,
    czzThreadTableViewLastCommandCellTypeReleaseToLoadMore = 1,
    czzThreadTableViewLastCommandCellTypeLoading = 2,
    czzThreadTableViewLastCommandCellTypeNoMore = 3
} czzThreadTableViewLastCommandCellType;

@interface czzThreadTableView : UITableView
@property (nonatomic, strong) czzOnScreenCommandViewController *upDownViewController;
@property (nonatomic, assign) czzThreadTableViewLastCommandCellType lastCellType;

-(void)scrollToTop;
@end
