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

#define kLastCleanDate @"kLastCleanDate"
#define kCleanInterval 2592000

#import <Foundation/Foundation.h>

@class czzImageCentre;
@class czzImageDownloader;
@protocol czzImageCentreProtocol <NSObject>
@optional
-(void)imageCentreDownloadUpdated:(czzImageCentre*)imgCentre downloader:(czzImageDownloader*)downloader progress:(CGFloat)progress;
-(void)imageCentreDownloadFinished:(czzImageCentre*)imgCentre downloader:(czzImageDownloader*)downloader wasSuccessful:(BOOL)success;
-(void)imageCentreDownloadStarted:(czzImageCentre*)imgCentre downloader:(czzImageDownloader*)downloader;
@end

@interface czzImageCentre : NSObject
@property (nonatomic, strong) NSMutableOrderedSet *currentImageDownloaders;
@property (nonatomic, strong) NSMutableOrderedSet *currentThumbnailDownloaders;
@property (nonatomic, strong) NSMutableSet *currentLocalImages;
@property (nonatomic, strong) NSMutableSet *currentLocalThumbnails;
@property (nonatomic, strong) NSMutableArray *localImagesArray;
@property (nonatomic, strong) NSMutableArray *localThumbnailsArray;
@property (assign, nonatomic) BOOL ready;
@property (nonatomic, weak) id<czzImageCentreProtocol> delegate;

+(instancetype)sharedInstance;
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
