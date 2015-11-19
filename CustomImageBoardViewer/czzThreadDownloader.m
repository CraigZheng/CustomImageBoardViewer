//
//  czzThreadDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 15/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadDownloader.h"

#import "czzURLDownloader.h"
#import "czzJSONProcessor.h"

@interface czzThreadDownloader() <czzURLDownloaderProtocol, czzJSONProcessorDelegate>
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
    DLog(@"Start downloading: %@", targetURL.absoluteString);
    if ([self.delegate respondsToSelector:@selector(threadDownloaderBeginsDownload:)]) {
        [self.delegate threadDownloaderBeginsDownload:self];
    }
}

- (void)stop {
    if (self.urlDownloader) {
        DLog(@"%s", __PRETTY_FUNCTION__);
        self.urlDownloader.delegate = nil;
        [self.urlDownloader stop];
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
        targetURLString = [targetURLString stringByReplacingOccurrencesOfString:kForum
                                                                     withString:self.parentForum.name];
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (self.parentThread) {
                [self.jsonProcessor processSubThreadFromData:downloadedData
                                                    forForum:self.parentForum];
            } else if (self.parentForum) {
                [self.jsonProcessor processThreadListFromData:downloadedData
                                                     forForum:self.parentForum];
            }
        });
    } else {
        // Inform delegate about the failure.
        [self.delegate threadDownloaderCompleted:self
                                         success:NO
                               downloadedThreads:nil
                                           error:nil];
    }
}

- (void)downloadUpdated:(czzURLDownloader *)downloader progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(threadDownloaderDownloadUpdated:progress:)]) {
        [self.delegate threadDownloaderDownloadUpdated:self
                                              progress:progress];
    }
}

#pragma mark - czzJSONProcessorDelegate

- (void)threadListProcessed:(czzJSONProcessor *)processor :(NSArray *)newThread :(BOOL)success {
    // TODO: give proper error.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate threadDownloaderCompleted:self
                                         success:success
                               downloadedThreads:newThread
                                           error:nil];
    });
}

- (void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)parentThread :(NSArray *)newThread :(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate threadDownloaderCompleted:self
                                         success:success
                               downloadedThreads:newThread
                                           error:nil];
    });
}

- (void)pageNumberUpdated:(NSInteger)currentPage allPage:(NSInteger)allPage {
    if ([self.delegate respondsToSelector:@selector(pageNumberUpdated:allPage:)]) {
        [self.delegate pageNumberUpdated:currentPage allPage:allPage];
    }
}

@end
