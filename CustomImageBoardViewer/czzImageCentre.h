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
#import <Foundation/Foundation.h>

@class czzImageCentre;
@class czzImageDownloader;
@protocol czzImageCentreProtocol <NSObject>
@optional
-(void)imageCentreDownloadUpdated:(czzImageCentre*)imgCentre downloader:(czzImageDownloader*)downloader progress:(CGFloat)progress;
-(void)imageCentreDownloadFinished:(czzImageCentre*)imgCentre downloader:(czzImageDownloader*)downloader wasSuccessful:(BOOL)success;
@end

@interface czzImageCentre : NSObject
@property NSMutableSet *currentImageDownloaders;
@property NSMutableSet *currentLocalImages;
@property NSMutableSet *currentLocalThumbnails;
@property NSMutableArray *localImagesArray;
@property NSMutableArray *localThumbnailsArray;
@property Boolean ready;
@property id<czzImageCentreProtocol> delegate;

+(id)sharedInstance;
+ (NSDate*) getModificationDateForFileAtPath:(NSString*)path;

-(void)scanCurrentLocalImages;
-(void)downloadThumbnailWithURL:(NSString*)imgURL isCompletedURL:(BOOL)completeURL;
-(void)downloadImageWithURL:(NSString*)imgURL isCompletedURL:(BOOL)completeURL;
-(Boolean)containsImageDownloaderWithURL:(NSString*)imgURL;
-(void)stopAndRemoveImageDownloaderWithURL:(NSString*)imgURL;
-(void)removeAllImages;
-(void)removeFullSizeImages;
-(void)removeThumbnails;
-(NSString*)totalSizeForFullSizeImages;
-(NSString*)totalSizeForThumbnails;
@end
