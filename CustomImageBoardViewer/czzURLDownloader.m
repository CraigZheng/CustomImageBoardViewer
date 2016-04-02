//
//  czzXMLDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzURLDownloader.h"
#import "AFNetworking.h"
#import "DeviceHardware.h"

@interface czzURLDownloader()
@property NSMutableData *receivedData;
@property (strong, nonatomic) NSURL *targetURL;
@property NSUInteger expectedLength;
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;
@end

@implementation czzURLDownloader
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
        self.delegate = delegate;
        
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        self.dataTask = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            if ([self.delegate respondsToSelector:@selector(downloadUpdated:progress:)]) {
                [self.delegate downloadUpdated:self progress:(float)downloadProgress.completedUnitCount / (float)downloadProgress.totalUnitCount];
            }
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if ([self.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
                [self.delegate downloadOf:response.URL successed:error == nil result:responseObject];
            }
        }];
         
        if (now) {
            [self start];
        }
    }
    return self;
}

-(void)start{
    if (self.dataTask) {
        [self.dataTask resume];
        DDLogDebug(@"%@ make request to: %@", NSStringFromClass(self.class), self.targetURL);
        DDLogDebug(@"Header fields: %@", self.dataTask.originalRequest.allHTTPHeaderFields);
    }
}

-(void)stop{
    if (self.dataTask.state == NSURLSessionTaskStateRunning)
        [self.dataTask cancel];
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
    return self.dataTask.state == NSURLSessionTaskStateRunning;
}

@end
