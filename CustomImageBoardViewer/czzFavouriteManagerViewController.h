//
//  czzFavouriteManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 21/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const bookmarkIndex;
extern NSInteger const watchIndex;
extern NSInteger const historyIndex;

@class czzThreadTableView;

@interface czzFavouriteManagerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *titleSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *historyTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet czzThreadTableView *tableView;
@property NSMutableOrderedSet *threads;
@property (assign, nonatomic) NSInteger launchToIndex;

- (IBAction)editAction:(id)sender;
- (IBAction)titleSegmentedControlAction:(id)sender;
- (IBAction)historyTypeSegmentedControlAction:(id)sender;


+(UIViewController*)newInNavigationController;
@end
