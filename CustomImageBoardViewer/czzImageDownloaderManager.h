//
//  czzImageDownloaderManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzWeakReferenceDelegate.h"

@class czzImageDownloaderManager;
@class czzImageDownloader;

@protocol czzImageDownloaderManagerDelegate <NSObject>
@optional
-(void)imageDownloaderManager:(czzImageDownloaderManager*)manager downloadedUpdated:(czzImageDownloader*)downloader imageName:(NSString*)imageName progress:(CGFloat)progress;
-(void)imageDownloaderManager:(czzImageDownloaderManager*)manager downloadedFinished:(czzImageDownloader*)downloader imageName:(NSString*)imageName wasSuccessful:(BOOL)success;
-(void)imageDownloaderManager:(czzImageDownloaderManager*)manager downloadedStarted:(czzImageDownloader*)downloader imageName:(NSString*)imageName wasSuccessful:(BOOL)success;
@end

@interface czzImageDownloaderManager : NSObject

-(void)addDelegate:(id<czzImageDownloaderManagerDelegate>)delegate;
-(void)removeDelegate:(id<czzImageDownloaderManagerDelegate>)delegate;
-(BOOL)hasDelegate:(id<czzImageDownloaderManagerDelegate>)delegate;

-(void)downloadThumbnailWithURL:(NSString*)imageURL;
-(void)downloadImageWithURL:(NSString*)imageURL;
-(BOOL)isImageDownloading:(NSString*)imageName;
-(void)stopDownloadingImage:(NSString*)imageName;

+(instancetype)sharedManager;
@end
