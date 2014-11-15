//
//  czzMiniThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@class czzThread;
@protocol czzMiniThreadViewControllerProtocol <NSObject>
@optional
-(void)miniThreadViewFinishedLoading:(BOOL)successful;
-(void)miniThreadWantsToOpenThread:(czzThread*)thread;
@end

@interface czzMiniThreadViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *threadTableView;
@property (nonatomic) NSInteger threadID;
@property (weak, nonatomic) IBOutlet UINavigationItem *miniThreadNaBarItem;
@property (weak, nonatomic) IBOutlet UINavigationBar *miniThreadNavBar;
@property id<czzMiniThreadViewControllerProtocol> delegate;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)openThreadAction:(id)sender;
@end
