//
//  czzLaunchPopUpNotificationViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzLaunchPopUpNotificationViewController : UIViewController
@property (nonatomic, strong) NSString *htmlContent;
// On dismiss block.
@property (nonatomic, copy) void (^completionHandler)(void);


@end
