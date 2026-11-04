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
@property NSMutableData *receivedData;
@property (strong, nonatomic) NSURL *targetURL;
@property NSUInteger expectedLength;
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;
@property (assign, nonatomic) BOOL observerAdded;
@end

@implementation czzURLDownloader
@synthesize receivedData;
@synthesize expectedLength;
@synthesize backgroundTaskID;

+(void)sendSynchronousRequestWithURL:(NSURL *)url completionHandler:(void (^)(BOOL, NSData *, NSError *))completionHandler {
    czzURLDownloader *urlDownloader = [czzURLDownloader new];
    urlDownloader.targetURL = url;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSData *downloadedData = nil;
    __block NSError *taskError = nil;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:urlDownloader.targetURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        downloadedData = data;
        taskError = error;
        dispatch_semaphore_signal(sema);
    }];
    [task resume];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    completionHandler(taskError == nil && downloadedData != nil, downloadedData, taskError);
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
        self.delegate = delegate;
        
        __weak typeof(self) weakSelf = self;
        NSURLSession *session = [NSURLSession sharedSession];
        self.dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf removeProgressObserver];
            [strongSelf notifyDelegateAboutStateChanged];
            if ([strongSelf.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
                [strongSelf.delegate downloadOf:response.URL successed:error == nil result:data];
            }
        }];
        
        if (self.dataTask.progress) {
            [self.dataTask.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];
            self.observerAdded = YES;
        }
        
        if (now) {
            [self start];
        }
    }
    return self;
}

- (void)removeProgressObserver {
    if (self.observerAdded && self.dataTask.progress) {
        @try {
            [self.dataTask.progress removeObserver:self forKeyPath:@"fractionCompleted"];
        } @catch (NSException *exception) {
        }
        self.observerAdded = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"fractionCompleted"] && object == self.dataTask.progress) {
        if ([self.delegate respondsToSelector:@selector(downloadUpdated:progress:)]) {
            CGFloat progress = (CGFloat)self.dataTask.progress.fractionCompleted;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.delegate downloadUpdated:self progress:progress];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)start{
    if (self.dataTask) {
        [self.dataTask resume];
        [self notifyDelegateAboutStateChanged];
        DDLogDebug(@"%@ make request to: %@", NSStringFromClass(self.class), self.targetURL);
        DDLogDebug(@"Header fields: %@", self.dataTask.originalRequest.allHTTPHeaderFields);
    }
}

-(void)stop{
    [self removeProgressObserver];
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        [self.dataTask cancel];
        [self notifyDelegateAboutStateChanged];
    }
    self.dataTask = nil;
}

- (void)dealloc {
    [self removeProgressObserver];
}

- (void)notifyDelegateAboutStateChanged {
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(downloadStateChanged:)]) {
            [self.delegate downloadStateChanged:self];
        }
    }];
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

#pragma mark - Getters

- (BOOL)isDownloading {
    BOOL isDownloading = self.dataTask.state == NSURLSessionTaskStateRunning;
    return isDownloading;
}

@end
