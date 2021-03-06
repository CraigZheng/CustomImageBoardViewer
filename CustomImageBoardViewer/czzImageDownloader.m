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
@property (strong, nonatomic) NSString *baseURLString;
@property (strong, nonatomic) NSString *fileName;
@property long long fileSize;
@property NSUInteger downloadedSize;
@property (strong, nonatomic) NSString *internalSavePath;
@property (strong, nonatomic) NSHTTPURLResponse *response;
@end

@implementation czzImageDownloader
@synthesize urlConn;
@synthesize imageURLString;
@synthesize receivedData;
@synthesize delegate;
@synthesize isThumbnail;
@synthesize fileSize;
@synthesize downloadedSize;
@synthesize backgroundTaskID;

-(void)start{
    if (!imageURLString)
        return;
    if (urlConn){
        [urlConn cancel];
    }
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.targetURLString]];
    urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
    
    // Notify delegate that download is started
    if ([delegate respondsToSelector:@selector(downloadStarted:)]){
        [delegate downloadStarted:self];
    }
}

-(void)stop{
    if (urlConn) {
        [urlConn cancel];
        if ([self.delegate respondsToSelector:@selector(downloadStopped:)]) {
            [self.delegate downloadStopped:self];
        }
    }
}

#pragma mark - Getters

-(NSString *)targetURLString {
    NSString *targetURLString;
    if (![imageURLString hasPrefix:@"http"])
        targetURLString = [self.baseURLString stringByAppendingPathComponent:[imageURLString stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
    else
        targetURLString = imageURLString;
    return targetURLString;
}

- (NSString *)baseURLString {
    if (isThumbnail) {
        return [settingCentre thumbnail_host];
    } else {
        return [settingCentre image_host];
    }
}


#pragma NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if ([delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:)]){
        [delegate downloadFinished:self success:NO isThumbnail:isThumbnail saveTo:Nil];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        self.response = (NSHTTPURLResponse *)response;
    }
    receivedData = [NSMutableData new];
    fileSize = [response expectedContentLength];
    downloadedSize = 0;

    self.backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // Cancel the connection
        [connection cancel];
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
    downloadedSize = receivedData.length;
    //inform delegate that a part of download is finished
    if ([delegate respondsToSelector:@selector(downloaderProgressUpdated:expectedLength:downloadedLength:)]){
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
    NSString *filePath = [basePath stringByAppendingPathComponent:self.fileName];
    NSError *error;
    BOOL saveSuccessful;
    if (receivedData.length && self.response.statusCode == 200) {
        [receivedData writeToFile:filePath options:NSDataWritingAtomic error:&error];
        self.internalSavePath = filePath;
        saveSuccessful = error == nil;
    } else {
        saveSuccessful = NO;
    }
    if ([delegate respondsToSelector:@selector(downloadFinished:success:isThumbnail:saveTo:)]){
        if (error){
            DDLogDebug(@"%@", error);
        }
        [delegate downloadFinished:self success:saveSuccessful isThumbnail:isThumbnail saveTo:filePath];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
    // Dereference the urlConn.
    urlConn = nil;

}

//current downloading progress
-(CGFloat)progress{
    double pro = (double)downloadedSize / (double)fileSize;
    return pro;
}

#pragma mark - Getters

//determine if 2 downloaders are equal by compare the target URL
-(BOOL)isEqual:(id)object{
    if ([object isKindOfClass:[czzImageDownloader class]]) {
        czzImageDownloader *incomingDownloader = (czzImageDownloader*)object;
        return [incomingDownloader.targetURLString isEqualToString:self.targetURLString];
    }
    return NO;
}

-(NSUInteger)hash{
    return imageURLString.hash;
}

-(NSString *)savePath {
    return self.internalSavePath;
}

- (NSString *)fileName {
    return self.urlConn.originalRequest.URL.lastPathComponent;
}

@end
