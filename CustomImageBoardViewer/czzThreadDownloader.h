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
- (void)threadDownloaderProcessUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress;
@end

@interface czzThreadDownloader : NSObject
@property (nonatomic, strong) czzThread *parentThread;
@property (nonatomic, strong) czzForum *parentForum;

@property (nonatomic, weak) id<czzThreadDownloaderDelegate>delegate;
@end
