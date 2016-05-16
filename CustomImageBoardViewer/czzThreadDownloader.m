//
//  czzThreadDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 15/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadDownloader.h"

#import "czzThread.h"
#import "czzForum.h"
#import "czzSettingsCentre.h"

@interface czzThreadDownloader()
@property (nonatomic, strong) czzURLDownloader *urlDownloader;
@property (nonatomic, strong) czzJSONProcessor *jsonProcessor;

@property (nonatomic, readonly) NSString * targetURLString;
@end

@implementation czzThreadDownloader

#pragma mark - init

- (instancetype)initWithForum:(czzForum *)forum {
    self = [self init];
    if (self) {
        self.parentForum = forum;
    }
    return self;
}

- (instancetype)initWithForum:(czzForum *)forum andThread:(czzThread *)thread{
    self = [self init];
    if (self) {
        self.parentThread = thread;
        self.parentForum = forum;
    }
    return self;
}

- (void)start {
    [self stop];
    NSURL *targetURL = [NSURL URLWithString:[self.targetURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    self.urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:targetURL
                                                            delegate:self
                                                            startNow:YES];
    DDLogDebug(@"Start downloading: %@", targetURL.absoluteString);
}

- (void)stop {
    if (self.urlDownloader.isDownloading) {
        DDLogDebug(@"%s", __PRETTY_FUNCTION__);
        self.urlDownloader.delegate = nil;
        [self.urlDownloader stop];
    }
}

- (void)notifyDelegateSuccess:(BOOL)success downloadedThreads:(NSArray *)downloadedThreads error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(threadDownloaderCompleted:success:downloadedThreads:error:)]) {
        [self.delegate threadDownloaderCompleted:self
                                         success:success
                               downloadedThreads:downloadedThreads
                                           error:error];
    }
    if (self.completionHandler) {
        self.completionHandler(success, downloadedThreads, error);
    }
}

- (void)notifyDelegatePageNumberUpdated:(NSInteger)current total:(NSInteger)total {
    if ([self.delegate respondsToSelector:@selector(pageNumberUpdated:allPage:)]) {
        [self.delegate pageNumberUpdated:current allPage:total];
    }
}

#pragma mark - Setters

- (void)setParentForum:(czzForum *)parentForum {
    _parentForum = parentForum;
}

- (void)setParentThread:(czzThread *)parentThread {
    _parentThread = parentThread;
}

#pragma mark - Getters

- (BOOL)isDownloading {
    BOOL isDownloading = self.urlDownloader.isDownloading;
    return isDownloading;
}

- (NSString *)targetURLString {
    NSString *targetURLString;

    // Thread have higher priority than forum.
    if (self.parentThread) {
        // For browsing a thread.
        targetURLString = [settingCentre thread_content_host];
        targetURLString = [targetURLString stringByReplacingOccurrencesOfString:kParentID
                                                                     withString:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
    } else if (self.parentForum) {
        // For browsing forum.
        targetURLString = [settingCentre thread_list_host];
        targetURLString = [targetURLString stringByReplacingOccurrencesOfString:kForumID
                                                                     withString:[NSString stringWithFormat:@"%ld", (long)self.parentForum.forumID]];
    }
    assert(targetURLString.length != 0);
    targetURLString = [targetURLString stringByReplacingOccurrencesOfString:kPageNumber
                                                                 withString:[NSString stringWithFormat:@"%ld", (long)self.pageNumber]];
    return targetURLString;
}

/**
 Page number should not be smaller than 1.
 */
- (NSInteger)pageNumber {
    if (_pageNumber <= 1) {
        _pageNumber = 1;
    }
    return _pageNumber;
}

- (czzJSONProcessor *)jsonProcessor {
    if (!_jsonProcessor) {
        _jsonProcessor = [czzJSONProcessor new];
        _jsonProcessor.delegate = self;
    }
    return _jsonProcessor;
}

#pragma mark - czzURLDownloaderDelegate

- (void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    if (successed) {
        if (self.parentThread) {
            [self.jsonProcessor processSubThreadFromData:downloadedData
                                                forForum:self.parentForum];
        } else if (self.parentForum) {
            [self.jsonProcessor processThreadListFromData:downloadedData
                                                 forForum:self.parentForum];
        }
    } else {
        // Inform delegate about the failure.
        [self notifyDelegateSuccess:NO downloadedThreads:nil error:nil];
    }
}

- (void)downloadUpdated:(czzURLDownloader *)downloader progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(threadDownloaderDownloadUpdated:progress:)]) {
        [self.delegate threadDownloaderDownloadUpdated:self
                                              progress:progress];
    }
}

- (void)downloadStateChanged:(czzURLDownloader *)downloader {
    if ([self.delegate respondsToSelector:@selector(threadDownloaderStateChanged:)]) {
        [self.delegate threadDownloaderStateChanged:self];
    }
}

#pragma mark - czzJSONProcessorDelegate

- (void)threadListProcessed:(czzJSONProcessor *)processor :(NSArray *)newThread :(BOOL)success {
    // TODO: give proper error.
    [self notifyDelegatePageNumberUpdated:success ? self.pageNumber : self.pageNumber-- total:INT32_MAX];
    [self notifyDelegateSuccess:success downloadedThreads:newThread error:nil];
}

- (void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)parentThread :(NSArray *)newThread :(BOOL)success {
    // If not success, or no thread has been downloaded, reverse the page number by 1.
    if (!success || newThread.count == 0) {
        self.pageNumber --;
    }
    CGFloat totalPages = (CGFloat)parentThread.responseCount / (CGFloat)settingCentre.response_per_page;
    self.totalPages = ceilf(totalPages);
    self.parentThread = parentThread;
    // Notify delegate about the page number
    [self notifyDelegatePageNumberUpdated:self.pageNumber
                                    total:self.totalPages];
    
    // Notify delegate about the successful download.
    [self notifyDelegateSuccess:success downloadedThreads:newThread error:nil];
}

@end
