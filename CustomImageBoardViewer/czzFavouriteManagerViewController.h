//
//  czzFavouriteManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 21/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzMenuEnabledTableViewCell.h"


@interface czzFavouriteManagerViewController : UITableViewController
@property NSMutableArray *threads;
@property NSString *title;
- (IBAction)editAction:(id)sender;
@end
