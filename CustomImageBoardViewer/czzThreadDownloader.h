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
- (void)threadDownloaderBeganDownload:(czzThreadDownloader *)downloader;
- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error;

@optional
- (void)threadDownloaderDownloadUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress;
@end

@interface czzThreadDownloader : NSObject
@property (nonatomic, assign) NSInteger pageNumber;

@property (nonatomic, weak) id<czzThreadDownloaderDelegate>delegate;

- (instancetype)initWithForum:(czzForum *)forum;
- (instancetype)initWithForum:(czzForum *)forum andThread:(czzThread *)thread;

- (void)start;
- (void)stop;
@end
