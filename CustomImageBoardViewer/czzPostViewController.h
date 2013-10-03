//
//  czzPostViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThread.h"

@interface czzPostViewController : UIViewController <UITextViewDelegate>
@property czzThread *thread;
@property czzThread *replyTo;
@property (strong, nonatomic) IBOutlet UITextView *postTextView;
@property (strong, nonatomic) IBOutlet UIToolbar *postToolbar;
@property (strong, nonatomic) IBOutlet UINavigationBar *postNaviBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;

- (IBAction)postAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)clearAction:(id)sender;
@end
