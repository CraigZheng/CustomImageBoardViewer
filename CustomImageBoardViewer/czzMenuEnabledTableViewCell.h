//
//  czzMenuEnabledTableViewCell.h
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzThreadViewController.h"

/*
 sub class uitableview cell to enable custom menu action
 */

@interface czzMenuEnabledTableViewCell : UITableViewCell
@property NSMutableArray *links;
@property (nonatomic) czzThread *myThread;
@end
