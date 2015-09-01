//
//  czzThreadTableView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzOnScreenCommandViewController.h"

#import "czzThreadViewCommandStatusCellViewController.h"

@interface czzThreadTableView : UITableView
@property (nonatomic, strong) czzOnScreenCommandViewController *upDownViewController;
@property (nonatomic, assign) czzThreadViewCommandStatusCellViewType lastCellType;
@property (nonatomic, strong) czzThreadViewCommandStatusCellViewController *lastCellCommandViewController;
-(void)scrollToTop;
@end
