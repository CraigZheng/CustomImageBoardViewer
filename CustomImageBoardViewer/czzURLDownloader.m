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
@property (strong, nonatomic) NSURL *targetURL;
@property NSUInteger expectedLength;
@end

@implementation czzURLDownloader
@synthesize urlConn;
@synthesize receivedData;
@synthesize expectedLength;
@synthesize backgroundTaskID;

+(void)sendSynchronousRequestWithURL:(NSURL *)url completionHandler:(void (^)(BOOL, NSData *, NSError *))completionHandler {
    czzURLDownloader *urlDownloader = [czzURLDownloader new];
    urlDownloader.targetURL = url;
    
    NSData *downloadedData;
    NSURLResponse *response;
    NSError *error;
    downloadedData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:urlDownloader.targetURL] returningResponse:&response error:&error];
    
    completionHandler(!error, downloadedData, error);
}

-(instancetype)initWithTargetURL:(NSURL *)url delegate:(id<czzURLDownloaderProtocol>)delegate startNow:(BOOL)now{
    return [self initWithTargetURL:url delegate:delegate startNow:now shouldUseDefaultCookit:YES];
}

- (instancetype)initWithTargetURL:(NSURL *)url delegate:(id<czzURLDownloaderProtocol>)delegate startNow:(BOOL)now shouldUseDefaultCookit:(BOOL)should {
    self = [super init];
    if (self){
        self.targetURL = url;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.targetURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
        [request setHTTPShouldHandleCookies:should];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"HavfunClient-%@", [DeviceHardware platform]] forHTTPHeaderField:@"User-Agent"];
        urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:now];
        self.delegate = delegate;
        if (now) {
            [self start];
        }
    }
    return self;
}

-(void)start{
    [urlConn start];
    DDLogDebug(@"%@ make request to: %@", NSStringFromClass(self.class), self.targetURL);
    DDLogDebug(@"Header fields: %@", urlConn.originalRequest.allHTTPHeaderFields);
}

-(void)stop{
    [urlConn cancel];
}

#pragma mark - Setters
-(void)setTargetURL:(NSURL *)targetURL {
    if ((!_targetURL)) {
        // Add bundle identifier and app ID to the target URL
        NSString *targetURLString = targetURL.absoluteString;
        if ([targetURLString rangeOfString:@"?"].location == NSNotFound) {
            targetURLString = [targetURLString stringByAppendingString:@"?"]; // Adding ? sign at the end to allow parsing by PHP.
        }
        targetURLString = [targetURLString stringByAppendingFormat:@"&appID=%@", [UIApplication appId]];
        targetURLString = [targetURLString stringByAppendingFormat:@"&version=%@", [UIApplication bundleVersion]];

        _targetURL = [NSURL URLWithString:targetURLString];
    } else {
        _targetURL = targetURL;
    }
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
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
        [self.delegate downloadOf:connection.currentRequest.URL successed:YES result:self.receivedData];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
    
}
@end
