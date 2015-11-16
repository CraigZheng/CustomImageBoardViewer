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

-(void)imageDownloaderManager:(czzImageDownloaderManager*)manager downloadedStarted:(czzImageDownloader*)downloader imageName:(NSString*)imageName;
-(void)imageDownloaderManager:(czzImageDownloaderManager*)manager downloadedStopped:(czzImageDownloader*)downloader imageName:(NSString*)imageName;

@end

@interface czzImageDownloaderManager : NSObject
@property (nonatomic, strong) NSMutableSet<czzImageDownloader*> *thumbnailDownloaders;
@property (nonatomic, strong) NSMutableSet<czzImageDownloader*> *imageDownloaders;
@property (nonatomic, readonly) NSArray *downloadedImages;

-(void)addDelegate:(id<czzImageDownloaderManagerDelegate>)delegate;
-(void)removeDelegate:(id<czzImageDownloaderManagerDelegate>)delegate;
-(BOOL)hasDelegate:(id<czzImageDownloaderManagerDelegate>)delegate;

-(void)downloadImageWithURL:(NSString*)imageURL isThumbnail:(BOOL)thumbnail;
-(void)stopDownloadingImage:(NSString*)imageName;
-(BOOL)isImageDownloading:(NSString *)imageName;

+(instancetype)sharedManager;
@end
