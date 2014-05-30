//
//  czzThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "IIViewDeckController.h"

@interface czzThreadViewController : UITableViewController
@property (nonatomic) czzThread *parentThread;
@property (strong, nonatomic) IBOutlet UITableView *threadTableView;
- (IBAction)moreAction:(id)sender;

-(void)saveThreadsToCache;
-(void)scrollTableViewToTop;
-(void)scrollTableViewToBottom;
@end
