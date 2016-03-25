//
//  czzMassiveThreadDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 8/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

/**
 A class for downloading everything within the given parent thread, currently doesn't support parentForum.
 */

#import "czzThreadDownloader.h"

@class czzMassiveThreadDownloader;
@protocol czzMassiveThreadDownloaderDelegate <czzThreadDownloaderDelegate>
@optional
- (void)massiveDownloaderUpdated:(czzMassiveThreadDownloader *)downloader;
- (void)massiveDownloader:(czzMassiveThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads errors:(NSArray *)errors;
@end

@interface czzMassiveThreadDownloader : czzThreadDownloader

@end
