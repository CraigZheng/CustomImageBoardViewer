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
#import "czzThreadTableView.h"
#import "czzThreadViewModelManager.h"

@class czzThread;
@interface czzHomeViewController : UIViewController <czzThreadListProtocol>
@property (weak, nonatomic) IBOutlet czzThreadTableView *threadTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *jumpBarButtonItem;

@property (strong) UIBarButtonItem *infoBarButton;
@property (weak, nonatomic) IBOutlet UIView *onScreenImageManagerViewContainer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forumListButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButton;
@property (strong, nonatomic) czzHomeViewModelManager* viewModelManager;

- (IBAction)sideButtonAction:(id)sender;
- (IBAction)moreAction:(id)sender;

- (IBAction)postAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)searchAction:(id)sender;
- (IBAction)bookmarkAction:(id)sender;
- (IBAction)settingsAction:(id)sender;

- (NSString*)saveCurrentState;
@end
