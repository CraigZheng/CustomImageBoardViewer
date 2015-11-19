//
//  czzThreadDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 15/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzThreadDownloader;
@protocol czzThreadDownloaderDelegate <NSObject>
- (void)threadDownloaderBeginsDownload:(czzThreadDownloader *)downloader;
- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error;

@optional
- (void)threadDownloaderDownloadUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress;
-(void)pageNumberUpdated:(NSInteger)currentPage allPage:(NSInteger)allPage;

@end

@interface czzThreadDownloader : NSObject
@property (nonatomic, assign) NSInteger pageNumber;

@property (nonatomic, weak) id<czzThreadDownloaderDelegate>delegate;
@property (nonatomic, strong) czzThread *parentThread;
@property (nonatomic, strong) czzForum *parentForum;
@property (nonatomic, copy) void(^completionHandler)(BOOL success, NSArray *downloadedThreads, NSError *error);

- (instancetype)initWithForum:(czzForum *)forum;
- (instancetype)initWithForum:(czzForum *)forum andThread:(czzThread *)thread;

- (void)start;
- (void)stop;
@end
