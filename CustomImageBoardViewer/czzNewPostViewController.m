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

@interface czzNewPostViewController ()<czzXMLDownloaderDelegate>
@property NSString *targetURLString;
@property NSURLConnection *urlConn;
@property NSMutableData *receivedResponse;
@end

@implementation czzNewPostViewController
@synthesize postButton, postNaviBar, postTextView, postToolbar;
@synthesize urlConn;
@synthesize targetURLString;
@synthesize receivedResponse;
@synthesize forumName;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    postTextView.inputAccessoryView = postToolbar;
    self.postNaviBar.topItem.title = [NSString stringWithFormat:@"新帖:%@", forumName];
    //URLs
    targetURLString = @"http://h.acfun.tv/api/thread/post_root";

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
    //&forumName parameter
    NSData *parentID = [[NSString stringWithFormat:@"&forumName=%@", self.forumName] dataUsingEncoding:NSUTF8StringEncoding];
    //&thread paramter
    NSData *content = [[NSString stringWithFormat:@"&content=%@", postTextView.text] dataUsingEncoding:NSUTF8StringEncoding];
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
