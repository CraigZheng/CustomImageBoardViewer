//
//  czzThreadTableViewDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeTableViewManager.h"
#import "czzThreadViewManager.h"

@interface czzThreadTableViewManager : czzHomeTableViewManager
@property (weak, nonatomic) czzThreadViewManager *threadViewManager;
@property (weak, nonatomic) czzThreadTableView *threadTableView;
@end
