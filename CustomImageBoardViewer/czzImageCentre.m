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
@property NSString *thumbnailFolder;
@property NSString *imageFolder;
@end

@implementation czzImageCentre
@synthesize currentImageDownloaders;
@synthesize currentLocalThumbnails;
@synthesize currentLocalImages;
@synthesize thumbnailFolder;
@synthesize imageFolder;

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
        [self scanCurrentLocalImages];
        currentImageDownloaders = [NSMutableSet new];
        NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        thumbnailFolder = [libraryPath stringByAppendingPathComponent:@"Thumbnails"];
        imageFolder = [libraryPath stringByAppendingPathComponent:@"Images"];
    }
    return self;
}

/*
 scan the library for downloaded images
 */
-(void)scanCurrentLocalImages{

    NSMutableSet *tempImgs = [NSMutableSet new];
    //files in thumbnail folder
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thumbnailFolder error:Nil];
    for (NSString *entity in files) {
        NSString *file = [thumbnailFolder stringByAppendingPathComponent:entity];
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
        NSString *file = [imageFolder stringByAppendingPathComponent:entity];
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
        [self stopAndRemoveImageDownloaderWithURL:imgURL];
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
        [self stopAndRemoveImageDownloaderWithURL:imgURL];
    }
    [imgDown start];
    [currentImageDownloaders addObject:imgDown];
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
    //construct an img downloader with given URL
    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
    imgDown.delegate = self;
    imgDown.imageURLString = imgURL;
    //if image downloader with save target url is present, return YES
    if ([currentImageDownloaders containsObject:imgDown]){
        NSPredicate *sameTargetURL = [NSPredicate predicateWithFormat:@"targetURLString == %@", imgDown.targetURLString];
        NSSet *downloadersWithSameTargetURL = [currentImageDownloaders filteredSetUsingPredicate:sameTargetURL];
        for (czzImageDownloader *downloader in downloadersWithSameTargetURL) {
            [downloader stop];
            [currentImageDownloaders removeObject:downloader];
        }
    }
}

#pragma mark czzImageDownloader delegate
-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)isThumbnail saveTo:(NSString *)path{
    //post a notification to inform other view controllers that a download is finished
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     imgDownloader, @"ImageDownloader",
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
        [userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"Success"];
        [[czzAppDelegate sharedAppDelegate] showToast:@"图片下载失败：请检查网络和储存空间"];
    }
    if (isThumbnail)
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"ThumbnailDownloaded" object:Nil userInfo:userInfo];
    else
        [[NSNotificationCenter defaultCenter]
             postNotificationName:@"ImageDownloaded" object:Nil userInfo:userInfo];
    //delete the image downloader
    NSPredicate *sameImgURL = [NSPredicate predicateWithFormat:@"imageURLString == %@", imgDownloader.imageURLString];
    NSSet *downloaderWithSameImageURLString = [currentImageDownloaders filteredSetUsingPredicate:sameImgURL];
    for (czzImageDownloader *imgDown in downloaderWithSameImageURLString) {
        [imgDown stop];
        [currentImageDownloaders removeObject:imgDown];
    }
}


-(void)downloaderProgressUpdated:(czzImageDownloader *)imgDownloader expectedLength:(NSUInteger)total downloadedLength:(NSUInteger)downloaded{
    //inform full size image download update
    if (!imgDownloader.isThumbnail){
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"ImageDownloaderProgressUpdated"
         object:Nil
         userInfo:[NSDictionary dictionaryWithObject:imgDownloader forKey:@"ImageDownloader"]];
    }
}

#pragma mark - remove images
-(void)removeFullSizeImages{
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageFolder error:nil];
    for (NSString *file in files) {
        [[NSFileManager defaultManager] removeItemAtPath:[imageFolder stringByAppendingPathComponent:file] error:nil];
    }
    [self scanCurrentLocalImages];
}

-(void)removeThumbnails{
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thumbnailFolder error:nil];
    //delete every files inside thumbnail folder and image folder
    for (NSString *file in files) {
        [[NSFileManager defaultManager] removeItemAtPath:[thumbnailFolder stringByAppendingPathComponent:file] error:nil];
    }
    [self scanCurrentLocalImages];
}

-(void)removeAllImages{
    [self removeThumbnails];
    [self removeFullSizeImages];
}

-(NSString *)totalSizeForFullSizeImages{
    return [self sizeOfFolder:imageFolder];
}

-(NSString *)totalSizeForThumbnails{
    return [self sizeOfFolder:thumbnailFolder];
}

-(NSString *)sizeOfFolder:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    
    //This line will give you formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}
@end
