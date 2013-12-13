//
//  czzImageDownloadCentre.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageCentre.h"
#import "czzImageDownloader.h"
#import "czzAppDelegate.h"


@interface czzImageCentre()<czzImageDownloaderDelegate>
@end

@implementation czzImageCentre
@synthesize currentImageDownloaders;
@synthesize currentLocalThumbnails;
@synthesize currentLocalImages;

+ (id)sharedInstance
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
- (id)init {
    if (self = [super init]) {
        currentLocalImages = [NSMutableSet new];
        currentLocalThumbnails = [NSMutableSet new];
        currentImageDownloaders = [NSMutableSet new];
    }
    return self;
}

/*
 scan the library for downloaded images
 */
-(void)scanCurrentLocalThumbnails{
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *thumbnailFolder = [libraryPath stringByAppendingPathComponent:@"Thumbnails"];
    NSString *imageFolder = [libraryPath stringByAppendingPathComponent:@"Images"];
    NSMutableSet *tempImgs = [NSMutableSet new];
    //files in thumbnail folder
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thumbnailFolder error:Nil];
    for (NSString *entity in files) {
        NSString *file = [libraryPath stringByAppendingPathComponent:entity];
        if ([file.pathExtension.lowercaseString isEqualToString:@"jpg"] ||
            [file.pathExtension.lowercaseString isEqualToString:@"jpeg"] ||
            [file.pathExtension.lowercaseString isEqualToString:@"png"] ||
            [file.pathExtension.lowercaseString isEqualToString:@"gif"])
        {
            UIImage *previewImage = [UIImage imageWithContentsOfFile:file];
            //if the given file can be construct as an image, add the path to current local images set
            if (previewImage)
               [tempImgs addObject:file];
        }
    }
    //Images folder
    currentLocalThumbnails = tempImgs;
    tempImgs = [NSMutableSet new];
    files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageFolder error:Nil];
    for (NSString *entity in files) {
        NSString *file = [libraryPath stringByAppendingPathComponent:entity];
        if ([file.pathExtension.lowercaseString isEqualToString:@"jpg"] ||
            [file.pathExtension.lowercaseString isEqualToString:@"jpeg"] ||
            [file.pathExtension.lowercaseString isEqualToString:@"png"] ||
            [file.pathExtension.lowercaseString isEqualToString:@"gif"])
        {
            UIImage *previewImage = [UIImage imageWithContentsOfFile:file];
            //if the given file can be construct as an image, add the path to current local images set
            if (previewImage)
                [tempImgs addObject:file];
        }
    }
    currentLocalImages = tempImgs;
}

-(void)downloadThumbnailWithURL:(NSString *)imgURL{
    //1. check local library for same image
    for (NSString *file in currentLocalThumbnails) {
        //if there's already an image file with the same name, then there is no need to redownload it
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
            return;
    }
    
    //2. constrct an image downloader with the provided url
    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
    imgDown.delegate = self;
    imgDown.isThumbnail = YES;
    imgDown.imageURLString = imgURL;
    //3. check current image downloaders for image downloader with same target url
    //if image downloader with save target url is present, stop that one and add the new downloader in, and start the new one
    if ([currentImageDownloaders containsObject:imgDown]){
        NSPredicate *sameTargetURL = [NSPredicate predicateWithFormat:@"imageURLString == %@", imgDown.imageURLString];
        NSSet *downloadersWithSameTargetURL = [currentImageDownloaders filteredSetUsingPredicate:sameTargetURL];
        for (czzImageDownloader *downloader in downloadersWithSameTargetURL) {
            [downloader stop];
            [currentImageDownloaders removeObject:downloader];
        }
    }
    [imgDown start];
    [currentImageDownloaders addObject:imgDown];
}

-(void)downloadImageWithURL:(NSString*)imgURL{
    //1. check local library for same image
    for (NSString *file in currentLocalImages) {
        //if there's already an image file with the same name, then there is no need to redownload it
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
            return;
    }
    
    //2. constrct an image downloader with the provided url
    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
    imgDown.delegate = self;
    imgDown.imageURLString = imgURL;
    //3. check current image downloaders for image downloader with same target url
    //if image downloader with save target url is present, stop that one and add the new downloader in, and start the new one
    if ([currentImageDownloaders containsObject:imgDown]){
        NSPredicate *sameTargetURL = [NSPredicate predicateWithFormat:@"imageURLString == %@", imgDown.imageURLString];
        NSSet *downloadersWithSameTargetURL = [currentImageDownloaders filteredSetUsingPredicate:sameTargetURL];
        for (czzImageDownloader *downloader in downloadersWithSameTargetURL) {
            [downloader stop];
            [currentImageDownloaders removeObject:downloader];
        }
    }
    [imgDown start];
    [currentImageDownloaders addObject:imgDown];
}

#pragma czzImageDownloader delegate
-(void)downloadFinished:(NSString *)target success:(BOOL)success isThumbnail:(BOOL)isThumbnail saveTo:(NSString *)path{
    //stop and delete the image downloader
    NSPredicate *sameImgURL = [NSPredicate predicateWithFormat:@"imageURLString == %@", target];
    NSSet *downloaderWithSameImageURLString = [currentImageDownloaders filteredSetUsingPredicate:sameImgURL];
    //post a notification to inform other view controllers that a download is finished
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     target, @"imageURLString",
                                     path, @"FilePath", nil];
    if (success){
        //inform receiver that download is successed
        [userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"Success"];
        if (isThumbnail)
            [currentLocalThumbnails addObject:path];
        else {
            [currentLocalImages addObject:path];
            
            [[czzAppDelegate sharedAppDelegate] showToast:@"图片下载好了"];
        }
    } else {
        //inform receiver that download is failed
        [userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"Success"];
    }
    if (isThumbnail)
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"ThumbnailDownloaded" object:Nil userInfo:userInfo];
    else
        [[NSNotificationCenter defaultCenter]
             postNotificationName:@"ImageDownloaded" object:Nil userInfo:userInfo];
    for (czzImageDownloader *downloader in downloaderWithSameImageURLString) {
        [downloader stop];
        [currentImageDownloaders removeObject:downloader];
    }
}
@end
