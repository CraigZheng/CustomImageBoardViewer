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

@class czzThread;
@interface czzHomeViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UITableView *threadTableView;
@property (nonatomic) NSString *forumName;
@property NSMutableArray *threads;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuBarButton;
@property (weak, nonatomic) IBOutlet UIView *bannerViewContainer;

- (IBAction)sideButtonAction:(id)sender;
- (IBAction)moreAction:(id)sender;

- (IBAction)postAction:(id)sender;
- (IBAction)jumpAction:(id)sender;
- (IBAction)searchAction:(id)sender;
- (IBAction)bookmarkAction:(id)sender;
- (IBAction)settingsAction:(id)sender;


-(void)prepareToEnterBackground; //entering background, save forumName, threads, selected threads, content offset(position in tableview), should open thread view controller with selected thread
-(void)restoreFromBackground; //restore the above settings if threads are empty
-(void)scrollTableViewToTop;
-(void)scrollTableViewToBottom;

-(void)pushViewController:(UIViewController*)viewController :(BOOL)animated; //allow other view controllers to gain access to this controller's navigation controller
@end
