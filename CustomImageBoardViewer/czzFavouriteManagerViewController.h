//
//  czzFavouriteManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 21/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzFavouriteManagerViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *titleSegmentedControl;
@property NSMutableOrderedSet *threads;

- (IBAction)editAction:(id)sender;
- (IBAction)titleSegmentedControlAction:(id)sender;


+(UIViewController*)newInNavigationController;
@end
