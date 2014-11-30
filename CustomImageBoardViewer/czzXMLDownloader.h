//
//  czzXMLDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzXMLDownloader;

@protocol czzXMLDownloaderDelegate <NSObject>
@optional
-(void)downloadOf:(NSURL*)xmlURL successed:(BOOL)successed result:(NSData*)xmlData;
-(void)downloadUpdated:(czzXMLDownloader*)downloader progress:(CGFloat)progress;
@end

@interface czzXMLDownloader : NSObject<NSURLConnectionDelegate>
@property (nonatomic) NSURL *targetURL;
@property id<czzXMLDownloaderDelegate>  delegate;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;

-(id)initWithTargetURL:(NSURL*)url delegate:(id<czzXMLDownloaderDelegate>)delegate startNow:(BOOL)now;
-(void)start;
-(void)stop;
@end
