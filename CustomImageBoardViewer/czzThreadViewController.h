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

@interface czzThreadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) czzThread *parentThread;
@property (strong, nonatomic) IBOutlet UITableView *threadTableView;
@property BOOL shouldHideImageForThisForum;
@property NSString *shouldHighlightSelectedUser;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;
@property (weak, nonatomic) IBOutlet UIView *onScreenImageManagerViewContainer;

- (IBAction)moreAction:(id)sender;
- (IBAction)replyAction:(id)sender;
- (IBAction)starAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)reportAction:(id)sender;
- (IBAction)shareAction:(id)sender;

-(void)saveThreadsToCache;
-(void)scrollTableViewToTop;
-(void)scrollTableViewToBottom;

@end
