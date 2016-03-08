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
@end

@implementation czzMassiveThreadDownloader
@dynamic delegate;

- (void)start {
    // Must make sure the parentThread is not nil.
    assert(self.parentThread);
    [super start];
}

- (void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)parentThread :(NSArray *)newThread :(BOOL)success {
    // Let the super class finish its processing first.
    [super subThreadProcessedForThread:processor :parentThread :newThread :success];
    [self.bulkThreads addObjectsFromArray:newThread];
    
    // If success and self.pageNumber not equals to self.total pages, load more.
    if (success) {
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

#pragma mark - Getters

- (NSMutableArray *)bulkThreads {
    if (!_bulkThreads) {
        _bulkThreads = [NSMutableArray new];
    }
    return _bulkThreads;
}

@end
