//
//  czzMiniThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzMiniThreadViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *threadTableView;
@property NSInteger threadID;
@end
