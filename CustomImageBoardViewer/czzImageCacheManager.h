//
//  czzImageDownloadCentre.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//
/*
 czzImageDownloadCentre singleton, allows multiple image downloaders to run simoutaneously, and notify appropriate observer that images have been downloaded.
 it also serves as the service centre of local images, feeding images to appropriate view controllers, and preventing same image being downloaded twice.
 */

#define THUMBNAIL_DOWNLOADED_NOTIFICATION @"ThumbnailDownloaded"

#import <Foundation/Foundation.h>

@class czzImageCacheManager;
@class czzImageDownloader;
@protocol czzImageCentreProtocol <NSObject>
@optional
-(void)imageCentreDownloadUpdated:(czzImageCacheManager*)imgCentre downloader:(czzImageDownloader*)downloader progress:(CGFloat)progress;
-(void)imageCentreDownloadFinished:(czzImageCacheManager*)imgCentre downloader:(czzImageDownloader*)downloader wasSuccessful:(BOOL)success;
-(void)imageCentreDownloadStarted:(czzImageCacheManager*)imgCentre downloader:(czzImageDownloader*)downloader;
@end

@interface czzImageCacheManager : NSObject
@property (nonatomic, strong) NSMutableOrderedSet *currentImageDownloaders;
@property (nonatomic, strong) NSMutableOrderedSet *currentThumbnailDownloaders;
@property (nonatomic, strong) NSArray<NSURL *> *thumbnailImages;
@property (nonatomic, strong) NSArray<NSURL *> *fullsizeImages;

@property (nonatomic, weak) id<czzImageCentreProtocol> delegate;

-(void)downloadThumbnailWithURL:(NSString*)imgURL isCompletedURL:(BOOL)completeURL;
-(void)downloadImageWithURL:(NSString*)imgURL isCompletedURL:(BOOL)completeURL;
-(Boolean)containsImageDownloaderWithURL:(NSString*)imgURL;
-(void)stopAndRemoveImageDownloaderWithURL:(NSString*)imgURL;

-(void)reloadCaches;
-(void)removeAllImages;
-(void)removeFullSizeImages;
-(void)removeThumbnails;
-(NSString*)totalSizeForFullSizeImages;
-(NSString*)totalSizeForThumbnails;

-(BOOL)hasImageWithName:(NSString*)imageName;
-(BOOL)hasThumbnailWithName:(NSString*)thumbnailImageName;
-(NSURL*)pathForImageWithName:(NSString*)imageName;
-(NSURL*)pathForThumbnailWithName:(NSString*)thumbnailImageName;

+(instancetype)sharedInstance;

@end
