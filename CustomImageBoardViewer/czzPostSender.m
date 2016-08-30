//
//  czzPostSender.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPostSender.h"
#import "czzPost.h"
#import "czzSettingsCentre.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"

@interface czzPostSender() <NSURLConnectionDataDelegate>
@property czzPost *myPost;
@property NSURLConnection *urlConn;
@property NSMutableURLRequest *urlRequest;
@property NSMutableData *requestBody;
@property NSMutableData *receivedData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
@end

@implementation czzPostSender
@synthesize name, email, title, content, imgData;
@synthesize myPost;
@synthesize urlConn;
@synthesize targetURL, forum, forumID, parentThread;
@synthesize urlRequest, requestBody;
@synthesize receivedData;

-(id)init{
    self = [super init];
    if (self){
        myPost = [czzPost new];
        requestBody = [NSMutableData new];
    }
    return self;
}

-(void)sendPost{
    switch (self.postMode) {
        case postSenderModeNew:
            targetURL = [NSURL URLWithString:[[settingCentre create_new_post_url] stringByReplacingOccurrencesOfString:kForum withString:[forum.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            break;
        case postSenderModeReply:
            targetURL = [NSURL URLWithString:[[settingCentre reply_post_url] stringByReplacingOccurrencesOfString:kParentID withString:[NSString stringWithFormat:@"%ld", (long)parentThread.ID]]];
            break;
        default:
            [NSException raise:@"ACTION NOT SUPPORTED" format:@"%s", __func__];
            break;
    }
    urlRequest = [self createMutableURLRequestWithURL:targetURL];
    if (myPost.isReady && urlRequest){
        [requestBody appendData:myPost.makeRequestBody];
        [urlRequest setHTTPBody:requestBody];
        urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
        DDLogDebug(@"Sending post to: %@", urlRequest);
    } else {
        if ([self.delegate respondsToSelector:@selector(postSender:completedPosting:message:response:)])
        {
            [self.delegate postSender:self
                     completedPosting:NO
                              message:@"请检查内容"
                             response:nil];
        }
        
    }
}

#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //inform the delegate
    if ([self.delegate respondsToSelector:@selector(postSender:completedPosting:message:response:)])
    {
        [self.delegate postSender:self
                 completedPosting:NO
                          message:[NSString stringWithFormat:@"网络错误"]
                         response:nil];
        DDLogDebug(@"%@", error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
    self.receivedResponse = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString *receivedResponseMessage = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    DDLogDebug(@"received response: \n%@", receivedResponseMessage);
    
    if ([self.delegate respondsToSelector:@selector(postSender:completedPosting:message:response:)])
    {
        if ([(NSHTTPURLResponse*)self.receivedResponse statusCode] == 200 && [receivedResponseMessage containsString:settingCentre.success_keyword]) {
            [self.delegate postSender:self
                     completedPosting:YES
                              message:@"成功"
                             response:receivedResponseMessage];
        } else {
            [self.delegate postSender:self
                     completedPosting:NO
                              message:[NSString stringWithFormat:@"Failed! Status code: %ld", (long)[(NSHTTPURLResponse*)self.receivedResponse statusCode]]
                             response:receivedResponseMessage];
        }
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (self.delegate && [self.delegate respondsToSelector:@selector(postSender:progressUpdated:)]) {
        [self.delegate postSender:self progressUpdated:(CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite];
    }
}

#pragma mark - Decode the self.response xml data - at Aug 2014, they've changed to return value to json format
-(void)response:(NSData*)jsonData{
    DDLogDebug(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
//    NSError *error;
//    NSDictionary *jsonResponse;
//    if (jsonData)
//        jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
//    else
//        error = [NSError errorWithDomain:@"Empty data!" code:9999 userInfo:nil];
//    if (error) {
//        if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
//        {
//            [self.delegate statusReceived:NO message:@"Can not parse responed message - format might not be json"];
//        }
//    }
//    if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
//    {
//        @try {
//            BOOL success = [[jsonResponse valueForKey:@"success"] boolValue];
//            NSString *errorMessage = [jsonResponse valueForKey:@"msg"];
//            [self.delegate statusReceived:success message:errorMessage];
//        }
//        @catch (NSException *exception) {
//            [self.delegate statusReceived:NO message:@"Unknown Error"];
//        }
//    }
}

#pragma mark - Setters, also sets the urlRequest and the first parameter(either parentID or forumName)

#pragma mark - Setters, while setting the members of this class, also set the member of myPost object

-(void)setForum:(czzForum *)f {
    forum = f;
    myPost.forum = forum;
    [self setForumID:[NSString stringWithFormat:@"%ld", (long)forum.forumID]];
}

-(void)setForumID:(NSString *)fid {
    forumID = fid;
    myPost.forumID = [self encodeNSString:forumID];
}

-(void)setParentThread:(czzThread *)thread{
    parentThread = thread;
    myPost.parentID = parentThread.ID;
}

-(void)setName:(NSString *)n{
    name = n;
    myPost.name = [self encodeNSString:name];
}

-(void)setEmail:(NSString *)e{
    email = e;
    myPost.email = [self encodeNSString:email];
}

-(void)setTitle:(NSString *)t{
    title = t;
    myPost.title = [self encodeNSString:title];
}

-(void)setContent:(NSString *)c{
    content = c;
    myPost.content = [self encodeNSString:content];
}

-(void)setImgData:(NSData *)i format:(NSString *)format{
    imgData = i;
    myPost.imgData = imgData;
    myPost.imageFormat = format;
}

-(NSMutableURLRequest*)createMutableURLRequestWithURL:(NSURL*)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [request setHTTPMethod:@"POST"];
    if (imgData) {
        [request setTimeoutInterval:120];
        NSString *boundary = @"-0-x-K-h-T-m-L-b-O-u-N-d-A-r-Y-";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    }
    //specify xml as return format
    [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
    
    return request;
}

-(NSString*)encodeNSString:(NSString*)unencodedString{
    //do nothing
    return unencodedString;
    /*
    NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                   NULL,
                                                                                   (CFStringRef)unencodedString,
                                                                                   NULL,
                                                                                   (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                   kCFStringEncodingUTF8 ));
    return encodedString;
     */
}
@end
