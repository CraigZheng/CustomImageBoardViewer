//
//  czzImageDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageDownloader.h"


@interface czzImageDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSString *targetURLString;
@property NSMutableData *receivedData;
@property NSString *baseURLString;
@property NSString *fileName;
@end

@implementation czzImageDownloader
@synthesize urlConn;
@synthesize imageURLString;
@synthesize baseURLString;
@synthesize targetURLString;
@synthesize receivedData;
@synthesize fileName;
@synthesize delegate;
@synthesize isThumbnail;

-(id)init{
    self = [super init];
    if (self){
        baseURLString = @"http://h.acfun.tv";
    }
    return self;
}

-(void)start{
    if (!imageURLString)
        return;
    if (urlConn){
        [urlConn cancel];
    }
    targetURLString = [baseURLString stringByAppendingPathComponent:[imageURLString stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:targetURLString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
}

-(void)stop{
    if (urlConn)
        [urlConn cancel];
}

#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //notify delegate that the download is failed
    if (delegate && [delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:)]){
        [delegate downloadFinished:imageURLString success:NO isThumbnail:isThumbnail saveTo:Nil];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
    fileName = response.suggestedFilename;
    //notify delegate that download is started
    if (delegate && [delegate respondsToSelector:@selector(downloadStarted:)]){
        [delegate downloadStarted:imageURLString];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //save to library directory
    NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //save to thumbnail folder or fullsize folder
    if (isThumbnail)
        basePath = [basePath stringByAppendingPathComponent:@"Thumbnails"];
    else
        basePath = [basePath
                    stringByAppendingPathComponent:@"Images"];
    NSString *filePath = [basePath stringByAppendingPathComponent:fileName];
    NSError *error;
    [receivedData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if (delegate && [delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:)]){
        if (error){
            NSLog(@"%@", error);
            [delegate downloadFinished:imageURLString success:NO isThumbnail:isThumbnail saveTo:filePath];
        } else {
            [delegate downloadFinished:imageURLString success:YES isThumbnail:isThumbnail saveTo:filePath];
        }
    }
}

//determine if 2 downloaders are equal by compare the target URL
-(BOOL)isEqual:(id)object{
    if ([object isKindOfClass:[czzImageDownloader class]]) {
        czzImageDownloader *incomingDownloader = (czzImageDownloader*)object;
        return [incomingDownloader.targetURLString isEqualToString:self.targetURLString];
    }
    return NO;
}
@end
