//
//  czzThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#define THREAD_VIEW_CONTROLLER @"thread_view_controller"

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzForum.h"
#import "czzSubThreadList.h"
#import "IIViewDeckController.h"

@interface czzThreadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *threadTableView;
@property NSString *shouldHighlightSelectedUser;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;
@property (weak, nonatomic) IBOutlet UIView *onScreenImageManagerViewContainer;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *numberBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;
@property UIBarButtonItem *numberBarButton;
@property BOOL shouldRestoreContentOffset;
@property czzSubThreadList *threadList;


- (IBAction)moreAction:(id)sender;
- (IBAction)replyAction:(id)sender;
- (IBAction)starAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)reportAction:(id)sender;
- (IBAction)shareAction:(id)sender;

-(void)scrollTableViewToTop;
-(void)scrollTableViewToBottom;

@end
