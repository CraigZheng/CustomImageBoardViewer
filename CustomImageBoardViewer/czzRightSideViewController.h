//
//  czzBottomViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzForum.h"
#import "czzThreadViewModelManager.h"
#import "IIViewDeckController.h"

@interface czzRightSideViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITableView *commandTableView;
@property (nonatomic, strong) czzThread *parentThread;
@property (nonatomic, strong) czzForum *forum;
@property (nonatomic, strong) czzThread *selectedThread;
@property (nonatomic, strong) czzThreadViewModelManager *threadViewModelManager;

-(void)reportAction;
-(void)replyMainAction;
-(void)replySelectedAction;
-(void)favouriteAction;
@end
