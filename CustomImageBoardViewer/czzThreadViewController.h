//
//  czzThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#define THREAD_VIEW_CONTROLLER_ID @"thread_view_controller"

#define THREAD_VIEW_CONTROLLER_STORYBOARD_NAME @"Main_iPhone"

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzForum.h"
#import "czzThreadTableView.h"
#import "czzThreadViewModelManager.h"
#import "IIViewDeckController.h"

extern NSString * const showThreadViewSegueIdentifier;

@interface czzThreadViewController : UIViewController <czzHomeViewModelManagerDelegate>

@property (weak, nonatomic) IBOutlet czzThreadTableView *threadTableView;
@property (strong, nonatomic) NSString *shouldHighlightSelectedUser;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;
@property (weak, nonatomic) IBOutlet UIView *onScreenImageManagerViewContainer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *jumpBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *numberBarButton;
@property (assign, nonatomic) BOOL shouldRestoreContentOffset;
@property (strong, nonatomic) czzThreadViewModelManager *viewModelManager;


- (IBAction)moreAction:(id)sender;
- (IBAction)replyAction:(id)sender;
- (IBAction)starAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)reportAction:(id)sender;
- (IBAction)shareAction:(id)sender;

- (NSString*)saveCurrentState;
@end
