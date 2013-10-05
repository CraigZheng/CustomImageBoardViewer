//
//  czzNewPostViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 30/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzXMLDownloader.h"
#import "czzNewPostViewController.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzPostSender.h"

@interface czzNewPostViewController ()<czzXMLDownloaderDelegate, czzPostSenderDelegate>
@property NSString *targetURLString;
@property NSURLConnection *urlConn;
@property NSMutableData *receivedResponse;
@property czzPostSender *postSender;
@end

@implementation czzNewPostViewController
@synthesize postButton, postNaviBar, postTextView, postToolbar;
@synthesize urlConn;
@synthesize targetURLString;
@synthesize receivedResponse;
@synthesize forumName;
@synthesize postSender;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    postTextView.inputAccessoryView = postToolbar;
    self.postNaviBar.topItem.title = [NSString stringWithFormat:@"新帖:%@", forumName];
    //URLs
    targetURLString = @"http://h.acfun.tv/api/thread/post_root";
    //make a new czzPostSender object, and assign the appropriate target URL and delegate
    postSender = [czzPostSender new];
    postSender.targetURL = [NSURL URLWithString:targetURLString];
    postSender.forumName = forumName;
    postSender.delegate = self;
}


- (IBAction)postAction:(id)sender {
    //construc a url request with given content
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
