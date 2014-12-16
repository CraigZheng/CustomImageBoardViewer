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
#import "czzSettingsCentre.h"

#include <sys/stat.h>

@interface czzImageCentre()<czzImageDownloaderDelegate>
@property NSString *thumbnailFolder;
@property NSString *imageFolder;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzImageCentre
@synthesize currentImageDownloaders;
@synthesize currentThumbnailDownloaders;
@synthesize currentLocalThumbnails;
@synthesize currentLocalImages;
@synthesize thumbnailFolder;
@synthesize imageFolder;
@synthesize localImagesArray;
@synthesize localThumbnailsArray;
@synthesize settingsCentre;
@synthesize delegate;

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
        currentImageDownloaders = [NSMutableOrderedSet new];
        currentThumbnailDownloaders = [NSMutableOrderedSet new];
        thumbnailFolder = [czzAppDelegate thumbnailFolder];
        imageFolder = [czzAppDelegate imageFolder];
        currentLocalImages = [NSMutableSet new];
        settingsCentre = [czzSettingsCentre sharedInstance];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self scanCurrentLocalImages];
        });
        
        //register notifications for saving and restoring image arrays
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
            if (settingsCentre.autoCleanImageCache) {
                if (![self isFileOlderThan30Days:file])
                    [tempImgs addObject:file];
            } else
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
            if (settingsCentre.autoCleanImageCache) {
                if (![self isFileOlderThan30Days:file])
                    [tempImgs addObject:file];
            } else
                [tempImgs addObject:file];
        }
    }
    currentLocalImages = tempImgs;
    //sort these arrays and store them into separated arrays
    localImagesArray = [NSMutableArray arrayWithArray:[self sortArrayOfFileWithModificationDate: [currentLocalImages allObjects]]];
    localThumbnailsArray = [NSMutableArray arrayWithArray:[self sortArrayOfFileWithModificationDate:[currentLocalThumbnails allObjects]]];
    self.ready = YES;
}

-(BOOL)isFileOlderThan30Days:(NSString*)filePath {
    NSDate *today = [NSDate new];
    @try {
        NSDate *fileModifiedDate = [czzImageCentre getModificationDateForFileAtPath:filePath];
        //if older than 30 days
        if ([today timeIntervalSinceDate:fileModifiedDate] > 2592000) {
            //delete this file and return YES
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            return YES;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return NO;
}

-(NSArray*)sortArrayOfFileWithModificationDate:(NSArray*)array {
    return [array sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        @try {
            NSDate *date1 = [czzImageCentre getModificationDateForFileAtPath:obj1];
            NSDate *date2 = [czzImageCentre getModificationDateForFileAtPath:obj2];
            return [date2 compare:date1];
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
        return NSOrderedSame;
    }];
}

-(void)downloadThumbnailWithURL:(NSString *)imgURL isCompletedURL:(BOOL)completeURL{
    //1. check local library for same image
    for (NSString *file in currentLocalThumbnails) {
        //if there's already an image file with the same name, then there is no need to redownload it
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
            return;
    }
    
    //2. constrct an image downloader with the provided url
    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
    imgDown.shouldAddHost = !completeURL;
    imgDown.delegate = self;
    imgDown.isThumbnail = YES;
    imgDown.imageURLString = imgURL;
    //3. check current image downloaders for image downloader with same target url
    //if image downloader with save target url is present, stop that one and add the new downloader in, and start the new one
    if ([currentThumbnailDownloaders containsObject:imgDown]){
        [self stopAndRemoveImageDownloaderWithURL:imgURL];
    }
    [imgDown start];
    [currentThumbnailDownloaders addObject:imgDown];
    //inform delegate
    if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadStarted:downloader:)])
    {
        [delegate imageCentreDownloadStarted:self downloader:imgDown];
    }
}

-(void)downloadImageWithURL:(NSString*)imgURL isCompletedURL:(BOOL)completeURL{
    //1. check local library for same image
    for (NSString *file in currentLocalImages) {
        //if there's already an image file with the same name, then there is no need to redownload it
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
            return;
    }
    
    //2. constrct an image downloader with the provided url
    czzImageDownloader *imgDown = [[czzImageDownloader alloc] init];
    imgDown.shouldAddHost = !completeURL;
    imgDown.delegate = self;
    imgDown.imageURLString = imgURL;
    //3. check current image downloaders for image downloader with same target url
    //if image downloader with save target url is present, stop that one and add the new downloader in, and start the new one
    if ([currentImageDownloaders containsObject:imgDown]){
        [self stopAndRemoveImageDownloaderWithURL:imgURL];
    }
    [imgDown start];
    [currentImageDownloaders addObject:imgDown];
    //inform delegate
    if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadStarted:downloader:)])
    {
        [delegate imageCentreDownloadStarted:self downloader:imgDown];
    }
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
        NSMutableSet *downloadersWithSameTargetURL = [NSMutableSet new];
        for (czzImageDownloader *downloader in currentImageDownloaders) {
            if ([downloader.imageURLString isEqualToString:imgDown.imageURLString])
                [downloadersWithSameTargetURL addObject:downloader];
        }
        for (czzImageDownloader *downloader in downloadersWithSameTargetURL) {
            [downloader stop];
            [currentImageDownloaders removeObject:downloader];
            //inform delegate
            if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadFinished:downloader:wasSuccessful:)]) {
                [delegate imageCentreDownloadFinished:self downloader:downloader wasSuccessful:NO];
            }
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
        if (isThumbnail) {
            [currentLocalThumbnails addObject:path];
            [localThumbnailsArray insertObject:path atIndex:0];
        }
        else {
            [currentLocalImages addObject:path];
            [localImagesArray insertObject:path atIndex:0];
        }
    } else {
        //inform receiver that download is failed
        [userInfo setObject:[NSNumber numberWithBool:NO] forKey:@"Success"];
        [[czzAppDelegate sharedAppDelegate] showToast:@"图片下载失败：请检查网络和储存空间"];
    }

    if (isThumbnail)
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"ThumbnailDownloaded" object:Nil userInfo:userInfo];

    NSMutableOrderedSet *setWithThisDownloader = imgDownloader.isThumbnail ? currentThumbnailDownloaders : currentImageDownloaders;
    NSPredicate *sameImgURL = [NSPredicate predicateWithFormat:@"imageURLString == %@", imgDownloader.imageURLString];
    NSSet *downloaderWithSameImageURLString = [setWithThisDownloader.set filteredSetUsingPredicate:sameImgURL];
    for (czzImageDownloader *imgDown in downloaderWithSameImageURLString) {
        [imgDown stop];
        [setWithThisDownloader removeObject:imgDown];
    }
    
    if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadFinished:downloader:wasSuccessful:)]) {
        [delegate imageCentreDownloadFinished:self downloader:imgDownloader wasSuccessful:success];
    }
}


-(void)downloaderProgressUpdated:(czzImageDownloader *)imgDownloader expectedLength:(NSUInteger)total downloadedLength:(NSUInteger)downloadedLength{
    //inform full size image download update
    if (!imgDownloader.isThumbnail){
        if (delegate && [delegate respondsToSelector:@selector(imageCentreDownloadUpdated:downloader:progress:)]) {
            [delegate imageCentreDownloadUpdated:self downloader:imgDownloader progress:(CGFloat)downloadedLength / (CGFloat)total];
        }
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

//this should speed up the process - copied from http://stackoverflow.com/questions/1523793/get-directory-contents-in-date-modified-order
+ (NSDate*) getModificationDateForFileAtPath:(NSString*)path {
    struct tm* date; // create a time structure
    struct stat attrib; // create a file attribute structure
    
    stat([path UTF8String], &attrib);   // get the attributes of afile.txt
    
    date = gmtime(&(attrib.st_mtime));  // Get the last modified time and put it into the time structure
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setSecond:   date->tm_sec];
    [comps setMinute:   date->tm_min];
    [comps setHour:     date->tm_hour];
    [comps setDay:      date->tm_mday];
    [comps setMonth:    date->tm_mon + 1];
    [comps setYear:     date->tm_year + 1900];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *modificationDate = [[cal dateFromComponents:comps] dateByAddingTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT]];
    
    return modificationDate;
}

@end
