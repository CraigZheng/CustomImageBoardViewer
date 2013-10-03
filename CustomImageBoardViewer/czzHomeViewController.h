//
//  czzViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"
#import "czzForumsViewController.h"

@interface czzHomeViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UITableView *threadTableView;
- (IBAction)sideButtonAction:(id)sender;
- (IBAction)newPostAction:(id)sender;

@end
