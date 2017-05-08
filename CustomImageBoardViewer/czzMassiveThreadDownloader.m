//
//  czzMassiveThreadDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 8/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzMassiveThreadDownloader.h"

@interface czzMassiveThreadDownloader()
@property (nonatomic, strong) NSMutableArray *bulkThreads;
@property (nonatomic, weak) id<czzMassiveThreadDownloaderDelegate> delegate;
@property (nonatomic, assign) BOOL manuallyStopped; // A Boolean to indicate that user has manually stopped the operation.
@end

@implementation czzMassiveThreadDownloader
@dynamic delegate;

- (void)start {
    // Must make sure the parentThread is not nil.
    assert(self.parentThread);
    self.manuallyStopped = NO;
    [super start];
}

- (void)stop {
    if (super.isDownloading) {
        [self markAsStop];
    }
    [super stop];
}

/**
 Set manuallyStopped to YES, and stop all sequencial downloading.
 */
- (void)markAsStop {
    self.manuallyStopped = YES;
    if ([self.delegate respondsToSelector:@selector(threadDownloaderStateChanged:)]) {
        [self.delegate threadDownloaderStateChanged:self];
    }
}

- (void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)parentThread :(NSArray *)newThread :(BOOL)success {
    [self.bulkThreads addObjectsFromArray:newThread];
    // Let the super class finish its processing.
    [super subThreadProcessedForThread:processor :parentThread :newThread :success];
    // A good time to inform delegate that a new page has been downloaded.
    if ([self.delegate respondsToSelector:@selector(massiveDownloaderUpdated:)]) {
        [self.delegate massiveDownloaderUpdated:self];
    }
    // If success and self.pageNumber not equals to self.total pages, load more.
    if (success && !self.manuallyStopped) {
        if (self.pageNumber < self.totalPages) {
            self.pageNumber ++;
            [self start];
        } else {
            // Notify delegate that the download is over.
            [self.delegate massiveDownloader:self
                                     success:success
                           downloadedThreads:self.bulkThreads
                                      errors:nil]; // TODO: an array of errors.
        }
    } else {
        // Download failed prematurelly.
        [self.delegate massiveDownloader:self
                                 success:success
                       downloadedThreads:self.bulkThreads
                                  errors:nil];
    }
}

- (void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    // Let super class handle most of the work.
    [super downloadOf:url successed:successed result:downloadedData];
    // If not successful, notify delegate.
    if (!successed) {
        // Stop manually.
        [self markAsStop];
        if ([self.delegate respondsToSelector:@selector(massiveDownloader:success:downloadedThreads:errors:)]) {
            [self.delegate massiveDownloader:self success:NO downloadedThreads:nil errors:nil];
        }
    }
}

#pragma mark - Getters

- (NSMutableArray *)bulkThreads {
    if (!_bulkThreads) {
        _bulkThreads = [NSMutableArray new];
    }
    return _bulkThreads;
}

- (BOOL)isDownloading {
    BOOL normalDownloading = super.isDownloading;
    BOOL massiveDownloading = self.pageNumber < self.totalPages;
    return (normalDownloading || massiveDownloading) && !self.manuallyStopped;
}

@end
