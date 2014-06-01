//
//  czzNotificationCentreTableViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzNotification.h"
#import "czzAppDelegate.h"

@interface czzNotificationCentreTableViewController : UITableViewController
@property czzNotification *currentNotification;
@property NSMutableArray *notifications;
@end
