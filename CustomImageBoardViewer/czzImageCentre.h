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

@interface czzImageCentre : NSObject
@property NSMutableSet *currentImageDownloaders;
@property NSMutableSet *currentLocalImages;
@property NSMutableSet *currentLocalThumbnails;+

(id)sharedInstance;

-(void)scanCurrentLocalImages;
-(void)downloadThumbnailWithURL:(NSString*)imgURL;
-(void)downloadImageWithURL:(NSString*)imgURL;
-(Boolean)containsImageDownloaderWithURL:(NSString*)imgURL;
-(void)stopAndRemoveImageDownloaderWithURL:(NSString*)imgURL;
-(void)removeAllImages;
-(void)removeFullSizeImages;
-(void)removeThumbnails;
-(NSString*)totalSizeForFullSizeImages;
-(NSString*)totalSizeForThumbnails;
@end
