//
//  czzLaunchPopUpNotificationViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@class czzLaunchPopUpNotification;

@interface czzLaunchPopUpNotificationViewController : UIViewController
@property (nonatomic, strong) NSString *htmlContent;
// On dismiss block.
@property (nonatomic, copy) void (^completionHandler)(void);
@property (nonatomic, strong) czzLaunchPopUpNotification* popUpNotification;

/**
 Only show when the notification date is larger than the last displayed date.
 */
- (Boolean)tryShow;
- (void)show;

@end
