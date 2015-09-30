//
//  czzImageDownloadCentre.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//



#import "czzImageCacheManager.h"
#import "czzImageDownloader.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "czzSettingsCentre.h"
#import "NSFileManager+Util.h"

#include <sys/stat.h>

@interface czzImageCacheManager()<czzImageDownloaderDelegate>
@end

@implementation czzImageCacheManager
@synthesize currentImageDownloaders;
@synthesize currentThumbnailDownloaders;
@synthesize delegate;

#pragma mark - Cache management.

/**
 Reset local caches.
 */
-(void)reloadCaches{
    self.thumbnailImages = nil;
    self.fullsizeImages = nil;
}


-(void)removeFullSizeImages{
    [[NSFileManager defaultManager] removeItemAtPath:[czzAppDelegate imageFolder] error:nil];
    [AppDelegate checkFolders];
    [self reloadCaches];
}

-(void)removeThumbnails{
    [[NSFileManager defaultManager] removeItemAtPath:[czzAppDelegate thumbnailFolder] error:nil];
    [AppDelegate checkFolders];
    [self reloadCaches];
}

-(void)removeAllImages{
    [self removeThumbnails];
    [self removeFullSizeImages];
}

-(NSString *)totalSizeForFullSizeImages{
    return [NSByteCountFormatter stringFromByteCount:[[NSFileManager defaultManager] sizeOfFolder:[czzAppDelegate imageFolder]] countStyle:NSByteCountFormatterCountStyleFile];
}

-(NSString *)totalSizeForThumbnails{
    return [NSByteCountFormatter stringFromByteCount:[[NSFileManager defaultManager] sizeOfFolder:[czzAppDelegate thumbnailFolder]] countStyle:NSByteCountFormatterCountStyleFile];
}

#pragma mark - Access to caches.

-(BOOL)hasImageWithName:(NSString *)imageName isThumbnail:(BOOL)thumbnail {
    NSURL *fileURL = [self pathForImageWithName:imageName isThumbnail:thumbnail];
    return [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
}

-(BOOL)hasImageWithName:(NSString *)imageName {
    return [self hasImageWithName:imageName isThumbnail:NO];
}

-(BOOL)hasThumbnailWithName:(NSString *)thumbnailImageName {
    return [self hasImageWithName:thumbnailImageName isThumbnail:YES];
}

-(NSURL *)pathForImageWithName:(NSString *)imageName {
    NSURL *fileURL;
    if ([self hasImageWithName:imageName]) {
        fileURL = [self pathForImageWithName:imageName isThumbnail:NO];
    }
    return fileURL;
}

-(NSURL *)pathForThumbnailWithName:(NSString *)thumbnailImageName {
    NSURL *fileURL;
    if ([self hasThumbnailWithName:thumbnailImageName]) {
        fileURL = [self pathForImageWithName:thumbnailImageName isThumbnail:YES];
    }
    return fileURL;
}

-(NSURL*)pathForImageWithName:(NSString *)imageName isThumbnail:(BOOL)thumbnail {
    NSURL *fileURL = [NSURL fileURLWithPath:thumbnail ? [[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:imageName] : [[czzAppDelegate imageFolder] stringByAppendingPathComponent:imageName]];
    
    return fileURL;
}

#pragma mark - Getters
-(NSArray *)fullsizeImages {
    if (!_fullsizeImages) {
        _fullsizeImages = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[czzAppDelegate imageFolder]] sortWithCreationDate:YES error:nil];
        // No image at the moment.
        if (!_fullsizeImages) {
            _fullsizeImages = [NSArray new];
        }
    }
    return _fullsizeImages;
}

-(NSArray *)thumbnailImages {
    if (!_thumbnailImages) {
        _thumbnailImages = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[czzAppDelegate thumbnailFolder]] sortWithCreationDate:YES error:nil];
        if (!_thumbnailImages) {
            _thumbnailImages = [NSArray new];
        }
    }
    return _thumbnailImages;
}

#pragma mark - Downloading

-(void)downloadThumbnailWithURL:(NSString *)imgURL isCompletedURL:(BOOL)completeURL{
//    //1. check local library for same image
//    for (NSString *file in currentLocalThumbnails) {
//        //if there's already an image file with the same name, then there is no need to redownload it
//        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
//            return;
//    }
//    
//    //2. constrct an image downloader with the provided url
//    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
//    imgDown.delegate = self;
//    imgDown.isThumbnail = YES;
//    imgDown.imageURLString = imgURL;
//    //3. check current image downloaders for image downloader with same target url
//    //if image downloader with save target url is present, stop that one and add the new downloader in, and start the new one
//    if ([currentThumbnailDownloaders containsObject:imgDown]){
//        [self stopAndRemoveImageDownloaderWithURL:imgURL];
//    }
//    [imgDown start];
//    [currentThumbnailDownloaders addObject:imgDown];
//    //inform delegate
//    if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadStarted:downloader:)])
//    {
//        [delegate imageCentreDownloadStarted:self downloader:imgDown];
//    }
}

-(void)downloadImageWithURL:(NSString*)imgURL isCompletedURL:(BOOL)completeURL{
//    //1. check local library for same image
//    for (NSString *file in currentLocalImages) {
//        //if there's already an image file with the same name, then there is no need to redownload it
//        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
//            return;
//    }
//    
//    //2. constrct an image downloader with the provided url
//    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
//    imgDown.delegate = self;
//    imgDown.imageURLString = imgURL;
//    //3. check current image downloaders for image downloader with same target url
//    //if image downloader with save target url is present, stop that one and add the new downloader in, and start the new one
//    if ([currentImageDownloaders containsObject:imgDown]){
//        [self stopAndRemoveImageDownloaderWithURL:imgURL];
//    }
//    [imgDown start];
//    [currentImageDownloaders addObject:imgDown];
//    //inform delegate
//    if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadStarted:downloader:)])
//    {
//        [delegate imageCentreDownloadStarted:self downloader:imgDown];
//    }
//    
//    [[AppDelegate window] makeToast:@"开始下载图片"];
}

//Check if given image URL is currently being downloaded
-(Boolean)containsImageDownloaderWithURL:(NSString *)imgURL{
    //construct an img downloader with given URL
    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
    imgDown.delegate = self;
    imgDown.imageURLString = imgURL;
    //if image downloader with save target url is present, return YES
    if ([currentImageDownloaders containsObject:imgDown]){
        return YES;
    }
    return NO;
}

//stop and remove the image downloader with given URL
-(void)stopAndRemoveImageDownloaderWithURL:(NSString *)imgURL{
//    //construct an img downloader with given URL
//    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
//    imgDown.delegate = self;
//    imgDown.imageURLString = imgURL;
//    //if image downloader with save target url is present, return YES
//    if ([currentImageDownloaders containsObject:imgDown]){
//        NSMutableSet *downloadersWithSameTargetURL = [NSMutableSet new];
//        for (czzImageDownloader *downloader in currentImageDownloaders) {
//            if ([downloader isEqual:imgDown])
//                [downloadersWithSameTargetURL addObject:downloader];
//        }
//        for (czzImageDownloader *downloader in downloadersWithSameTargetURL) {
//            [downloader stop];
//            [currentImageDownloaders removeObject:downloader];
//            //inform delegate
//            if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadFinished:downloader:wasSuccessful:)]) {
//                [delegate imageCentreDownloadFinished:self downloader:downloader wasSuccessful:NO];
//            }
//        }
//    }
//    
//    [[AppDelegate window] makeToast:@"下载终止"];
}

#pragma mark czzImageDownloader delegate
-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)isThumbnail saveTo:(NSString *)path{
//    //post a notification to inform other view controllers that a download is finished
//    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                     imgDownloader, @"ImageDownloader",
//                                     path, @"FilePath", nil];
//    if (success){
//        //inform receiver that download is successed
//        [userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"Success"];
//        if (isThumbnail) {
//            [currentLocalThumbnails addObject:path];
//            [localThumbnailsArray insertObject:path atIndex:0];
//        }
//        else {
//            [currentLocalImages addObject:path];
//            [localImagesArray insertObject:path atIndex:0];
//        }
//    } else {
//        //inform receiver that download is failed
//        [userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"Success"];
//        [AppDelegate showToast:@"图片下载失败：请检查网络和储存空间"];
//    }
//
//    if (isThumbnail)
//        [[NSNotificationCenter defaultCenter]
//         postNotificationName:THUMBNAIL_DOWNLOADED_NOTIFICATION object:Nil userInfo:userInfo];
//
//    NSMutableOrderedSet *setWithThisDownloader = imgDownloader.isThumbnail ? currentThumbnailDownloaders : currentImageDownloaders;
//    NSPredicate *sameImgURL = [NSPredicate predicateWithFormat:@"imageURLString == %@", imgDownloader.imageURLString];
//    NSSet *downloaderWithSameImageURLString = [setWithThisDownloader.set filteredSetUsingPredicate:sameImgURL];
//    for (czzImageDownloader *imgDown in downloaderWithSameImageURLString) {
//        [imgDown stop];
//        [setWithThisDownloader removeObject:imgDown];
//    }
//    
//    if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadFinished:downloader:wasSuccessful:)]) {
//        [delegate imageCentreDownloadFinished:self downloader:imgDownloader wasSuccessful:success];
//    }
}


-(void)downloaderProgressUpdated:(czzImageDownloader *)imgDownloader expectedLength:(NSUInteger)total downloadedLength:(NSUInteger)downloadedLength{
    //inform full size image download update
    if (!imgDownloader.isThumbnail){
        if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadUpdated:downloader:progress:)]) {
            [delegate imageCentreDownloadUpdated:self downloader:imgDownloader progress:(CGFloat)downloadedLength / (CGFloat)total];
        }
    }
}

+ (instancetype)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

@end
