//
//  czzNewPostViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 30/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzBlacklistEntity.h"

@interface czzNewPostViewController : UIViewController
@property NSString *forumName;
@property (strong, nonatomic) IBOutlet UITextView *postTextView;
@property (strong, nonatomic) IBOutlet UIToolbar *postToolbar;
@property (strong, nonatomic) IBOutlet UINavigationBar *postNaviBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property UIViewController *delegate;
@property (strong, nonatomic) czzBlacklistEntity *blacklistEntity;
- (IBAction)postAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)clearAction:(id)sender;
@end
