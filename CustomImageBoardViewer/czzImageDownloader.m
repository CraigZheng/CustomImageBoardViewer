//
//  czzImageDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageDownloader.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"

@interface czzImageDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@property NSString *baseURLString;
@property NSString *fileName;
@property long long fileSize;
@property NSUInteger downloadedSize;
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
@synthesize fileSize;
@synthesize downloadedSize;
@synthesize backgroundTaskID;
@synthesize shouldAddHost;


-(id)init{
    self = [super init];
    if (self){
        baseURLString = [[czzSettingsCentre sharedInstance] image_host];
        shouldAddHost = YES;
    }
    return self;
}

-(void)start{
    if (!imageURLString)
        return;
    if (urlConn){
        [urlConn cancel];
    }
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:targetURLString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
}

-(void)stop{
    if (urlConn)
        [urlConn cancel];
}

#pragma setter for imgURLString
-(void)setImageURLString:(NSString *)urlstring{
    imageURLString = urlstring;
    if (shouldAddHost)
        targetURLString = [baseURLString stringByAppendingPathComponent:[imageURLString stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
    else
        targetURLString = imageURLString;
}
#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //notify delegate that the download is failed
    if (delegate && [delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:)]){
        [delegate downloadFinished:self success:NO isThumbnail:isThumbnail saveTo:Nil];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedData = [NSMutableData new];
    fileName = response.suggestedFilename;
    fileSize = [response expectedContentLength];
    downloadedSize = 0;
    //notify delegate that download is started
    if (delegate && [delegate respondsToSelector:@selector(downloadStarted:)]){
        [delegate downloadStarted:self];
    }
    self.backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // Cancel the connection
        [connection cancel];
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSUInteger originalSize = receivedData.length;
    [receivedData appendData:data];
    downloadedSize = receivedData.length;
    //inform delegate that a part of download is finished
    if ([delegate respondsToSelector:@selector(downloaderProgressUpdated:expectedLength:downloadedLength:)]){
        //should only send notification every 1/10 of the total size
        if ((downloadedSize - originalSize) > fileSize / 10)
            [delegate downloaderProgressUpdated:self expectedLength:(NSUInteger)fileSize downloadedLength:downloadedSize];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //save to library directory
    NSString* basePath = [czzAppDelegate libraryFolder];
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
            DLog(@"%@", error);
            [delegate downloadFinished:self success:NO isThumbnail:isThumbnail saveTo:filePath];
        } else {
            [delegate downloadFinished:self success:YES isThumbnail:isThumbnail saveTo:filePath];
        }
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];

}

//current downloading progress
-(double)progress{
    double pro = (double)downloadedSize / (double)fileSize;
    return pro;
}

//determine if 2 downloaders are equal by compare the target URL
-(BOOL)isEqual:(id)object{
    if ([object isKindOfClass:[czzImageDownloader class]]) {
        czzImageDownloader *incomingDownloader = (czzImageDownloader*)object;
        return [incomingDownloader.imageURLString isEqualToString:self.imageURLString];
    }
    return NO;
}

-(NSUInteger)hash{
    return imageURLString.hash;
}
@end
