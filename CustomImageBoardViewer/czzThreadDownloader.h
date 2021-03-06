//
//  czzThreadDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 15/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzURLDownloader.h"
#import "czzJSONProcessor.h"

@class czzThread, czzForum;
@class czzThreadDownloader;
@protocol czzThreadDownloaderDelegate <NSObject>
- (void)threadDownloaderStateChanged:(czzThreadDownloader *)downloader;
- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error;

@optional
- (void)threadDownloaderDownloadUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress;
- (void)pageNumberUpdated:(NSInteger)currentPage allPage:(NSInteger)allPage;
@end

@interface czzThreadDownloader : NSObject <czzURLDownloaderProtocol, czzJSONProcessorDelegate>
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, weak) id<czzThreadDownloaderDelegate>delegate;
@property (nonatomic, strong) czzThread *parentThread;
@property (nonatomic, strong) czzForum *parentForum;
@property (nonatomic, readonly) BOOL isDownloading;
@property (nonatomic, readonly) NSString * targetURLString;
@property (nonatomic, copy) void(^completionHandler)(BOOL success, NSArray *downloadedThreads, NSError *error);

- (instancetype)initWithForum:(czzForum *)forum;
- (instancetype)initWithForum:(czzForum *)forum andThread:(czzThread *)thread;

- (void)start;
- (void)stop;
@end
