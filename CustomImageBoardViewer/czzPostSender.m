//
//  czzPostSender.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPostSender.h"
#import "czzPost.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"

@interface czzPostSender() <NSURLConnectionDelegate>
@property czzPost *myPost;
@property NSURLConnection *urlConn;
@property NSMutableURLRequest *urlRequest;
@property NSMutableData *requestBody;
@property NSMutableData *receivedResponse;
@end

@implementation czzPostSender
@synthesize name, email, title, content, imgData;
@synthesize myPost;
@synthesize urlConn;
@synthesize targetURL, forumName, parentID;
@synthesize urlRequest, requestBody;
@synthesize receivedResponse;
-(id)init{
    self = [super init];
    if (self){
        myPost = [czzPost new];
        requestBody = [NSMutableData new];
    }
    return self;
}

-(void)sendPost{
    urlRequest = [self createMutableURLRequestWithURL:targetURL];
    if (myPost.isReady && urlRequest){
        [requestBody appendData:myPost.makeRequestBody];
        [urlRequest setHTTPBody:requestBody];
        urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
    } else {
        if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
        {
            [self.delegate statusReceived:NO message:@"请检查帖子内容"];
        }
        
    }
}

#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //inform the delegate
    if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
    {
        [self.delegate statusReceived:NO message:[NSString stringWithFormat:@"无法发帖, 错误:网络错误"]];
        NSLog(@"%@", error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedResponse = [NSMutableData new];
    NSDictionary *dict = [(NSHTTPURLResponse*)response allHeaderFields];
    for (NSString *header in dict) {
        //NSLog(@"%@:%@", header, [dict objectForKey:header]);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedResponse appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self response:receivedResponse];
}

#pragma Decode the self.response xml data
-(void)response:(NSData*)xmlData{
    SMXMLDocument *xmlDoc = [[SMXMLDocument alloc]initWithData:xmlData error:nil];
    if (xmlDoc){
        BOOL success = NO;
        NSString *message = @"";
        for (SMXMLElement *child in xmlDoc.root.children){
            if ([child.name isEqualToString:@"success"]){
                success = [child.value boolValue];
            }
            if ([child.name isEqualToString:@"access_token"]){
                //if current access_token is nil, or the responding access_token does not match my current access token, save the responding access_token to a file for later use
                NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
                if (!oldToken || ![oldToken isEqualToString:child.value]){
                    [[NSUserDefaults standardUserDefaults] setObject:child.value forKey:@"access_token"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }

            }
            if ([child.name isEqualToString:@"msg"]){
                message = child.value;
            }
        }
        //inform the delegate
        if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
        {
            [self.delegate statusReceived:success message:message];
        }
    }
}

#pragma Setters, also sets the urlRequest and the first parameter(either parentID or forumName)
-(void)setTargetURL:(NSURL *)t{
    targetURL = t;
}

#pragma Setters, while setting the members of this class, also set the member of myPost object

-(void)setForumName:(NSString *)f{
    forumName = f;
    myPost.forumName = [self encodeNSString:forumName];
    //add the forumName parameter to the request
    //NSString *forumNamePara = [NSString stringWithFormat:@"&forumName=%@", self.forumName];
    //[requestBody appendData:[forumNamePara dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)setParentID:(NSInteger)p{
    parentID = p;
    myPost.parentID = parentID;
    //parentID parameter goes into request body
    //NSString *parentIDPara = [NSString stringWithFormat:@"&parentID=%ld", (long)parentID];
    //[requestBody appendData:[parentIDPara dataUsingEncoding:NSUTF8StringEncoding]];
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

-(void)setImgData:(NSData *)i{
    imgData = i;
    myPost.imgData = imgData;
}

-(NSMutableURLRequest*)createMutableURLRequestWithURL:(NSURL*)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [request setHTTPMethod:@"POST"];
    if (imgData) {
        [request setTimeoutInterval:120];
        NSString *boundary = @"-0-x-K-h-T-m-L-b-O-u-N-d-A-r-Y-";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        //NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded; boundary=%@",boundary];
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
