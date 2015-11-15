//
//  czzImageDownloaderManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzImageDownloaderManager.h"
#import "czzImageDownloader.h"

@interface czzImageDownloaderManager () <czzImageDownloaderDelegate>
@property (nonatomic, strong) NSMutableOrderedSet<czzWeakReferenceDelegate*> *delegates;

@end

@implementation czzImageDownloaderManager

#pragma mark - Getters

-(NSMutableOrderedSet *)delegates {
    if (!_delegates) {
        _delegates = [NSMutableOrderedSet new];
    }
    // Loop through all delegate objects in delegates, and remove those that are invalid.
    NSMutableArray *delegatesToRemove = [NSMutableArray new];
    for (czzWeakReferenceDelegate * weakRefDelegate in _delegates) {
        if (!weakRefDelegate.isValid) {
            [delegatesToRemove addObject:weakRefDelegate];
        }
    }
    [_delegates removeObjectsInArray:delegatesToRemove];
    return _delegates;
}

-(NSMutableSet *)thumbnailDownloaders {
    if (!_thumbnailDownloaders) {
        _thumbnailDownloaders = [NSMutableSet new];
    }
    return _thumbnailDownloaders;
}

-(NSMutableSet *)imageDownloaders {
    if (!_imageDownloaders) {
        _imageDownloaders = [NSMutableSet new];
    }
    return _imageDownloaders;
}

#pragma mark - Download management

-(void)downloadImageWithURL:(NSString *)imageURL isThumbnail:(BOOL)thumbnail{
    if (![self isImageDownloading:imageURL.lastPathComponent isThumbnail:thumbnail]) {
        czzImageDownloader *imageDownloader = [czzImageDownloader new];
        imageDownloader.imageURLString = imageURL;
        imageDownloader.isThumbnail = thumbnail;
        imageDownloader.delegate = self;
        if (thumbnail) {
            [self.thumbnailDownloaders addObject:imageDownloader];
        } else {
            [self.imageDownloaders addObject:imageDownloader];
        }
        // Start downloading.
        [imageDownloader start];
    } else {
        DLog(@"%@: %@ is downloading.", imageURL, thumbnail ? @"Fullsize Image" : @"Thumbnail Image");
    }
}

-(void)stopDownloadingImage:(NSString *)imageName {
    czzImageDownloader *downloaderToStop;
    for (czzImageDownloader *imageDownloader in self.imageDownloaders) {
        if ([imageDownloader.imageURLString.lastPathComponent isEqualToString:imageName]) {
            downloaderToStop = imageDownloader;
            break;
        }
    }
    if (downloaderToStop) {
        [self.imageDownloaders removeObject:downloaderToStop];
        [downloaderToStop stop];
        [self iterateDelegatesWithBlock:^(id<czzImageDownloaderManagerDelegate> delegate) {
            if ([delegate respondsToSelector:@selector(imageDownloaderManager:downloadedStopped:imageName:)]) {
                [delegate imageDownloaderManager:self downloadedStopped:downloaderToStop imageName:imageName];
            }
        }];
        DLog(@"Image download stopped by user: %@", imageName);
    }
}

-(BOOL)isImageDownloading:(NSString *)imageName {
    return [self isImageDownloading:imageName isThumbnail:NO];
}

-(BOOL)isImageDownloading:(NSString *)imageName isThumbnail:(BOOL)thumbnail{
    BOOL downloading = NO;
    for (czzImageDownloader *downloader in thumbnail ? self.thumbnailDownloaders : self.imageDownloaders) {
        if ([downloader.imageURLString.lastPathComponent isEqualToString:imageName]) {
            downloading = YES;
            break;
        }
    }
    return downloading;
}

#pragma mark - Delegates management
-(void)addDelegate:(id<czzImageDownloaderManagerDelegate>)delegate {
    [self.delegates addObject:[czzWeakReferenceDelegate weakReferenceDelegate:delegate]];
}

-(void)removeDelegate:(id<czzImageDownloaderManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

-(BOOL)hasDelegate:(id<czzImageDownloaderManagerDelegate>)delegate {
    return [self.delegates containsObject:delegate];
}

#pragma mark - czzImageDownloaderDelegate
-(void)downloaderProgressUpdated:(czzImageDownloader *)imgDownloader expectedLength:(NSUInteger)total downloadedLength:(NSUInteger)downloaded {
    [self iterateDelegatesWithBlock:^(id<czzImageDownloaderManagerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(imageDownloaderManager:downloadedUpdated:imageName:progress:)]) {
            [delegate imageDownloaderManager:self downloadedUpdated:imgDownloader imageName:imgDownloader.imageURLString.lastPathComponent progress:(CGFloat)downloaded / (CGFloat)total];
        }
    }];
}

-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString *)path {
    // Remove from either imageDownloaders or thumbnailDownloaders
    [self.imageDownloaders removeObject:imgDownloader];
    [self.thumbnailDownloaders removeObject:imgDownloader];

    [self iterateDelegatesWithBlock:^(id<czzImageDownloaderManagerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(imageDownloaderManager:downloadedFinished:imageName:wasSuccessful:)]) {
            [delegate imageDownloaderManager:self downloadedFinished:imgDownloader imageName:imgDownloader.imageURLString.lastPathComponent wasSuccessful:success];
        }
    }];
}

- (void)downloadStarted:(czzImageDownloader *)imgDownloader {
    [self iterateDelegatesWithBlock:^(id<czzImageDownloaderManagerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(imageDownloaderManager:downloadedStarted:imageName:)]) {
            [delegate imageDownloaderManager:self downloadedStarted:imgDownloader imageName:imgDownloader.imageURLString.lastPathComponent];
        }
    }];
}

-(void)downloadStopped:(czzImageDownloader *)imgDownloader {
    [self iterateDelegatesWithBlock:^(id<czzImageDownloaderManagerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(imageDownloaderManager:downloadedStopped:imageName:)]) {
            [delegate imageDownloaderManager:self downloadedStopped:imgDownloader imageName:imgDownloader.imageURLString.lastPathComponent];
        }
    }];
}

-(void)iterateDelegatesWithBlock:(void(^)(id<czzImageDownloaderManagerDelegate> delegate))block {
    for (czzWeakReferenceDelegate* weakRefDelegate in [self.delegates copy]) {
        id<czzImageDownloaderManagerDelegate> delegate = weakRefDelegate.delegate;
        block(delegate);
    }
}

+(instancetype)sharedManager
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
