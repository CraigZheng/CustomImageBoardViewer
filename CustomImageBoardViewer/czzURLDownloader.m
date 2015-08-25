//
//  czzXMLDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzURLDownloader.h"

#import "DeviceHardware.h"

@interface czzURLDownloader()
@property NSURLConnection *urlConn;
@property NSMutableData *receivedData;
@property NSUInteger expectedLength;
@end

@implementation czzURLDownloader
@synthesize urlConn;
@synthesize targetURL;
@synthesize receivedData;
@synthesize expectedLength;
@synthesize backgroundTaskID;

-(id)initWithTargetURL:(NSURL *)url delegate:(id<czzURLDownloaderProtocol>)delegate startNow:(BOOL)now{
    self = [super init];
    if (self){
        // Add bundle identifier and app ID to the target URL
        NSString *targetURLString = url.absoluteString;
        if (![targetURLString hasSuffix:@"?"]) {
            targetURLString = [targetURLString stringByAppendingString:@"?"]; // Adding ? sign at the end to allow parsing by PHP.
        }
        targetURLString = [targetURLString stringByAppendingFormat:@"&version=%@", [UIApplication bundleVersion]];
        targetURLString = [targetURLString stringByAppendingFormat:@"&appID=%@", [UIApplication appId]];
        
        targetURL = [NSURL URLWithString:targetURLString];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:targetURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
        [request setHTTPShouldHandleCookies:YES];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
        [request setValue:[NSString stringWithFormat:@"HavfunClient-%@", [DeviceHardware platform]] forHTTPHeaderField:@"User-Agent"];
        urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:now];
        if (now)
            DLog(@"%@ make request to: %@", NSStringFromClass(self.class), targetURL);
        self.delegate = delegate;
    }
    return self;
}

-(void)start{
    [urlConn start];
    DLog(@"%@ make request to: %@", NSStringFromClass(self.class), targetURL);
}

-(void)stop{
    [urlConn cancel];
}

#pragma NSURLConnectionDelegate
-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response{
    self.receivedData = [NSMutableData new];
    expectedLength = (NSUInteger)response.expectedContentLength;
    self.backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [connection cancel];
    }];
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)data{
    [self.receivedData appendData:data];
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadUpdated:progress:)]) {
        CGFloat progress = (CGFloat)self.receivedData.length / (CGFloat)expectedLength;
        [self.delegate downloadUpdated:self progress:progress];
    }
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
        [self.delegate downloadOf:connection.currentRequest.URL successed:NO result:nil];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
}

-(void)connectionDidFinishLoading:(NSURLConnection*)connection{
    if ([self.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
        [self.delegate downloadOf:connection.currentRequest.URL successed:YES result:self.receivedData];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];

}
@end
