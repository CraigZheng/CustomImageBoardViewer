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

#define REPLY_POST_URL @"http://h.acfun.tv/api/t/PARENT_ID/create"
#define NEW_POST_URL @"http://h.acfun.tv/api/FORUM_NAME/create"

@interface czzPostViewController : UIViewController <UITextViewDelegate>
@property czzThread *thread;
@property czzThread *replyTo;
@property czzForum *forum;
@property (nonatomic) NSInteger postMode;
@property (nonatomic) czzBlacklistEntity *blacklistEntity;
@property NSString *forumName;
@property (strong, nonatomic) IBOutlet UITextView *postTextView;
@property (strong, nonatomic) IBOutlet UINavigationBar *postNaviBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UIProgressView *sendingProgressVIew;
@property (weak, nonatomic) IBOutlet UIView *fillerBannerView;
@property (weak, nonatomic) IBOutlet UIView *postBackgroundView;

- (IBAction)postAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)pickImageAction:(id)sender;
- (IBAction)clearAction:(id)sender;

@end
