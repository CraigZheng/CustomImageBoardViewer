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
@property BOOL shouldHideImageForThisForum;
@property NSString *shouldHighlightSelectedUser;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;

- (IBAction)moreAction:(id)sender;
- (IBAction)replyAction:(id)sender;
- (IBAction)starAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)reportAction:(id)sender;
- (IBAction)shareAction:(id)sender;

-(void)saveThreadsToCache;
-(void)scrollTableViewToTop;
-(void)scrollTableViewToBottom;

-(void)prepareToEnterBackground;
-(void)restoreFromBackground;
@end
