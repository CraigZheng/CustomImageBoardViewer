//
//  czzLaunchPopUpNotificationViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@class czzLaunchPopUpNotificationViewController;
@protocol czzLaunchPopUpNotificationViewControllerDelegate <NSObject>
@optional
- (void)notificationViewController:(czzLaunchPopUpNotificationViewController *)viewController dismissedWithConfirmation:(BOOL)confirmed;

@end

@interface czzLaunchPopUpNotificationViewController : UIViewController
@property (nonatomic, strong) NSString *htmlContent;
// On dismiss block.
@property (nonatomic, copy) void (^completionHandler)(void);
@property (nonatomic, weak) id<czzLaunchPopUpNotificationViewControllerDelegate> delegate;

@end
