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
@synthesize targetURL, forumName, forumID, parentID;
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
            [self.delegate statusReceived:NO message:@"请检查内容"];
        }
        
    }
}

#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //inform the delegate
    if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
    {
        [self.delegate statusReceived:NO message:[NSString stringWithFormat:@"网络错误"]];
        NSLog(@"%@", error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedResponse = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedResponse appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self response:receivedResponse];
}

#pragma mark - Decode the self.response xml data - at Aug 2014, they've changed to return value to json format
-(void)response:(NSData*)jsonData{
    NSError *error;
    NSDictionary *jsonResponse;
    if (jsonData)
        jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else
        error = [NSError errorWithDomain:@"Empty data!" code:9999 userInfo:nil];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
        {
            [self.delegate statusReceived:NO message:@"Can not parse responed message - format might not be json"];
        }
    }
    if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
    {
        BOOL success = [[jsonResponse valueForKey:@"success"] boolValue];
        NSString *errorMessage = [jsonResponse valueForKey:@"error"];
        [self.delegate statusReceived:success message:errorMessage];
    }
}

#pragma mark - Setters, also sets the urlRequest and the first parameter(either parentID or forumName)
-(void)setTargetURL:(NSURL *)t{
    targetURL = t;
}

#pragma mark - Setters, while setting the members of this class, also set the member of myPost object

-(void)setForumName:(NSString *)f{
    forumName = f;
    myPost.forumName = [self encodeNSString:forumName];
}

-(void)setForumID:(NSString *)fid {
    forumID = fid;
    myPost.forumID = [self encodeNSString:forumID];
}

-(void)setParentID:(NSInteger)p{
    parentID = p;
    myPost.parentID = parentID;
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
