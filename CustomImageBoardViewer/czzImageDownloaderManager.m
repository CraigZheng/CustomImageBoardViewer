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
@property (nonatomic, strong) NSMutableOrderedSet *delegates;
@property 
@end

@implementation czzImageDownloaderManager

-(instancetype)init {
    self = [super init];
    if (self) {
        self.delegates = [NSMutableOrderedSet new];
    }
    return self;
}

#pragma mark - Download management.

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
-(void)downloadFinished:(czzImageDownloader *)imgDownloader success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString *)path {
    
}

- (void)downloadStarted:(czzImageDownloader *)imgDownloader {
    
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
