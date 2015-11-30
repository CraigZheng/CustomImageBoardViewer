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

#define PARENT_ID @"PARENT_ID"
#define FORUM_NAME @"FORUM_NAME"

typedef NS_ENUM(NSInteger, postViewControllerMode) {
    postViewControllerModeUnknown = 0,
    postViewControllerModeNew,
    postViewControllerModeReply,
    postViewControllerModeReport
};

@interface czzPostViewController : UIViewController <UITextViewDelegate>
@property czzThread *thread;
@property czzThread *replyTo;
@property czzForum *forum;
@property (nonatomic, strong) czzBlacklistEntity *blacklistEntity;
@property (nonatomic, assign) postViewControllerMode postMode;
@property (nonatomic, strong) NSString *prefilledString;

@property (strong, nonatomic) IBOutlet UITextView *postTextView;

@end
