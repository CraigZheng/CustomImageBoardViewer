//
//  czzPostViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPostViewController.h"
#import "czzPost.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzPostSender.h"

@interface czzPostViewController () <NSURLConnectionDelegate, czzPostSenderDelegate>
@property NSString *targetURLString;
@property NSURLConnection *urlConn;
@property NSMutableData *receivedResponse;
@property czzPostSender *postSender;
@end

@implementation czzPostViewController
@synthesize postTextView;
@synthesize postToolbar;
@synthesize thread;
@synthesize replyTo;
@synthesize postNaviBar;
@synthesize targetURLString;
@synthesize urlConn;
@synthesize postButton;
@synthesize receivedResponse;
@synthesize postSender;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    postTextView.inputAccessoryView = postToolbar;
    self.postNaviBar.topItem.title = [NSString stringWithFormat:@"回复"];
    //URLs
    targetURLString = @"http://h.acfun.tv/api/thread/post_sub";
    //content: reply to
    if (replyTo){
        self.postNaviBar.topItem.title = [NSString stringWithFormat:@"回复:%ld", (long)replyTo.ID];
        postTextView.text = [NSString stringWithFormat:@">>%ld\n\n", (long)replyTo.ID];
    }
    //make a new czzPostSender object, and assign the appropriate target URL and delegate
    postSender = [czzPostSender new];
    postSender.targetURL = [NSURL URLWithString:targetURLString];
    postSender.parentID = thread.ID;
    postSender.delegate = self;
}

- (IBAction)postAction:(id)sender {
    postSender.content = postTextView.text;
    [postSender sendPost];
    [postTextView resignFirstResponder];
    [postButton setEnabled:NO];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"正在发送..."];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//delete everything from the text view
- (IBAction)clearAction:(id)sender {
    postTextView.text = @"";
    [postTextView resignFirstResponder];
}

#pragma czzPostSender delegate
-(void)statusReceived:(BOOL)status message:(NSString *)message{
    if (status) {
        [self dismissViewControllerAnimated:YES completion:^{
            //dismiss this view controller and upon its dismiss, notify user that the message is posted
            [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"帖子已发"];
        }];
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:message duration:3.0 position:@"top" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];

    }
    [postButton setEnabled:YES];
}
@end
