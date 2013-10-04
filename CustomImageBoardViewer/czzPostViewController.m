//
//  czzPostViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPostViewController.h"
#import "czzReply.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"

@interface czzPostViewController () <NSURLConnectionDelegate>
@property NSString *targetURLString;
@property NSURLConnection *urlConn;
@property NSMutableData *receivedResponse;
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
}


- (IBAction)postAction:(id)sender {
    //construc a url request with given content
    NSURLRequest *request = [self urlRequestWithUserData];
    //kick off the url connection
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [postTextView resignFirstResponder];
    //disable the post button to prevent double posting
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

#pragma Construct a suitable URL request with the given data
-(NSURLRequest*)urlRequestWithUserData{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:targetURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
    //&parentID parameter
    NSData *parentID = [[NSString stringWithFormat:@"&parentID=%ld", (long)thread.ID] dataUsingEncoding:NSUTF8StringEncoding];
    //&thread paramter
    NSData *content = [[[NSString stringWithFormat:@"&content=%@", postTextView.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    //compress into 1 data object
    NSMutableData *requestBody = [NSMutableData new];
    [requestBody appendData:parentID];
    [requestBody appendData:content];
    //ready the URL request
    [urlRequest setHTTPBody:requestBody];

    return urlRequest;
}

#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"帖子无法发出，请检查并重试" duration:3.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    [postButton setEnabled:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedResponse = [NSMutableData new];
    NSDictionary *dict = [(NSHTTPURLResponse*)response allHeaderFields];
    for (NSString *header in dict) {
        NSLog(@"%@:%@", header, [dict objectForKey:header]);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedResponse appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self response:self.receivedResponse];
}

#pragma Decode the self.response xml data
-(void)response:(NSData*)xmlData{
    SMXMLDocument *xmlDoc = [[SMXMLDocument alloc]initWithData:xmlData error:nil];
    if (xmlDoc){
        for (SMXMLElement *child in xmlDoc.root.children){
            if ([child.name isEqualToString:@"success"]){
                BOOL success = [child.value boolValue];
                if (success){
                    [self dismissViewControllerAnimated:YES completion:^{
                        //dismiss this view controller and upon its dismiss, notify user that the message is posted
                        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"帖子已发"];
                    }];
                    return;
                } else {
                    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"帖子无法发出，请检查并重试" duration:3.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
                    [postButton setEnabled:YES];

                }
            }
        }
    }
}
@end
