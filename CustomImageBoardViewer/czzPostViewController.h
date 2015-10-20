//
//  czzPostViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzBlacklistEntity.h"
#import "czzForum.h"

//post mode
#define NEW_POST 1
#define REPLY_POST 2
#define REPORT_POST 3

#define PARENT_ID @"PARENT_ID"
#define FORUM_NAME @"FORUM_NAME"

@interface czzPostViewController : UIViewController <UITextViewDelegate>
@property czzThread *thread;
@property czzThread *replyTo;
@property czzForum *forum;
@property (nonatomic, assign) NSInteger postMode;
@property (nonatomic, strong) czzBlacklistEntity *blacklistEntity;

@property (nonatomic, strong) NSString *prefilledString;

@property (strong, nonatomic) IBOutlet UITextView *postTextView;

@end
