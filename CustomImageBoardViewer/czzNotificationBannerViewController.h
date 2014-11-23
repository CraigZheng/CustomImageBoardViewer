//
//  czzNotificationBannerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

/*
 this class also works as the manager of notifications
 */
#import <UIKit/UIKit.h>
#import "czzNotification.h"

@interface czzNotificationBannerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIImageView *statusIcon;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property CGFloat constantHeight;
@property UIView *parentView;
@property UINavigationController *homeViewController;//to provide access to navigation controller and story board
@property czzNotification *currentNotification;
@property NSMutableOrderedSet *notifications;
@property (nonatomic) BOOL needsToBePresented;
@property NSTimeInterval notificationDownloadInterval;
@property NSTimeInterval textUpdateInterval;
@property (weak, nonatomic) IBOutlet UIButton *numberButton;

- (IBAction)dismissAction:(id)sender;
- (IBAction)tapOnViewAction:(id)sender;

-(BOOL)shouldShow; //should show notification if a new notification is available
-(void)show;
-(void)hide;
@end
