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

@interface czzImageCacheManager()
@end

@implementation czzImageCacheManager

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
