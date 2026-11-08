//
//  czzViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzHomeViewManager.h"

@class czzThread, czzThreadTableView;
@interface czzHomeViewController : UIViewController <czzHomeViewManagerDelegate>
@property (weak, nonatomic) czzThreadTableView *threadTableView;
@property (weak, nonatomic) UIBarButtonItem *jumpBarButtonItem;

@property (weak, nonatomic) UIBarButtonItem *infoBarButton;
@property (weak, nonatomic) UIView *onScreenImageManagerViewContainer;
@property (weak, nonatomic) UIBarButtonItem *forumListButton;
@property (weak, nonatomic) UIBarButtonItem *settingsBarButton;
@property (strong, nonatomic) czzHomeViewManager* homeViewManager;

- (IBAction)sideButtonAction:(id)sender;

- (IBAction)postAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)bookmarkAction:(id)sender;
- (IBAction)settingsAction:(id)sender;

@end
