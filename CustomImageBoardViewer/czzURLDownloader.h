//
//  czzXMLDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzURLDownloader;

@protocol czzURLDownloaderProtocol <NSObject>
-(void)downloadOf:(NSURL*)url successed:(BOOL)successed result:(NSData*)downloadedData;
@optional
-(void)downloadUpdated:(czzURLDownloader*)downloader progress:(CGFloat)progress;
@end

@interface czzURLDownloader : NSObject<NSURLConnectionDataDelegate>
@property (nonatomic) NSURL *targetURL;
@property (weak, nonatomic) id<czzURLDownloaderProtocol>  delegate;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;

-(id)initWithTargetURL:(NSURL*)url delegate:(id<czzURLDownloaderProtocol>)delegate startNow:(BOOL)now;
-(void)start;
-(void)stop;
@end
