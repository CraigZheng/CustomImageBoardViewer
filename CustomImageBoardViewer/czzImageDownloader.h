//
//  czzImageDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzImageDownloader;
/*
 delegate that notify a download has been finished - or failed
 */
@protocol czzImageDownloaderDelegate <NSObject>
-(void)downloadFinished:(czzImageDownloader*)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString*)path;
@optional
-(void)downloadStarted:(czzImageDownloader*)imgDownloader;
-(void)downloadStopped:(czzImageDownloader*)imgDownloader;

-(void)downloaderProgressUpdated:(czzImageDownloader*)imgDownloader expectedLength:(NSUInteger)total downloadedLength:(NSUInteger)downloaded;
@end

@interface czzImageDownloader : NSObject
@property (nonatomic) NSString *imageURLString;
@property (readonly, nonatomic) NSString *targetURLString;
@property (readonly, nonatomic) NSString *savePath;

@property (weak, nonatomic) id<czzImageDownloaderDelegate> delegate;
@property (assign, nonatomic) BOOL isThumbnail;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;

-(id)init;
-(void)start;
-(void)stop;
-(CGFloat)progress;
@end
