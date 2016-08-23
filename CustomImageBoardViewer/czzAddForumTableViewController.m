//
//  czzAddForumTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 24/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzAddForumTableViewController.h"

@interface czzAddForumTableViewController ()

@end

@implementation czzAddForumTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - UI actions.

- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
