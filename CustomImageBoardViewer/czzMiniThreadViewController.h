//
//  czzMiniThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol czzMiniThreadViewControllerProtocol <NSObject>
@optional
-(void)miniThreadViewFinishedLoading:(BOOL)successful;
@end

@interface czzMiniThreadViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *threadTableView;
@property (nonatomic) NSInteger threadID;
@property id<czzMiniThreadViewControllerProtocol> delegate;
@end
