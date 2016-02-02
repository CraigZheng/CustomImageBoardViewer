//
//  czzFavouriteManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 21/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@class czzThreadTableView;

@interface czzFavouriteManagerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *titleSegmentedControl;
@property (weak, nonatomic) IBOutlet czzThreadTableView *tableView;
@property NSMutableOrderedSet *threads;

- (IBAction)editAction:(id)sender;
- (IBAction)titleSegmentedControlAction:(id)sender;


+(UIViewController*)newInNavigationController;
@end
