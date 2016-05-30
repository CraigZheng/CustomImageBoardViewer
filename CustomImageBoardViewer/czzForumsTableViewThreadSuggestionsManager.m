//
//  czzForumsTableViewThreadSuggestionsManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzForumsTableViewThreadSuggestionsManager.h"

#import "czzPopularThreadsManager.h"

@interface czzForumsTableViewThreadSuggestionsManager()
@property (nonatomic, weak) czzPopularThreadsManager *popularThreadsManager;
@end

@implementation czzForumsTableViewThreadSuggestionsManager

- (instancetype)initWithPopularThreadsManager:(czzPopularThreadsManager *)manager {
    self = [self init];
    if (self) {
        _popularThreadsManager = manager;
    }
    return self;
}

#pragma mark - Getters

- (czzPopularThreadsManager *)popularThreadsManager {
    // Should never be nil.
    assert(_popularThreadsManager != nil);
    return _popularThreadsManager;
}

@end
