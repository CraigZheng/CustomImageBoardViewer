//
//  czzFeedbackViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzFeedback.h"
//#import "IIViewDeckController.h"


@interface czzFeedbackViewController : UIViewController
@property czzFeedback *myFeedback;
@property czzNotification *myNotification;
@property (strong, nonatomic) IBOutlet UITextView *contentTextView;
@end
