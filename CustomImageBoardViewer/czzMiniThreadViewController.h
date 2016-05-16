//
//  czzMiniThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzModalViewController.h"
#import "czzThread.h"

@interface czzMiniThreadViewController : czzModalViewController
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threadTableViewHeight;
@property (weak, nonatomic) IBOutlet UITableView *threadTableView;
@property (nonatomic) czzThread *myThread;

@end
