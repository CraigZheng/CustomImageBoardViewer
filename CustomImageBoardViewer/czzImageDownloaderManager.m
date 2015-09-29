//
//  czzImageDownloaderManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzImageDownloaderManager.h"

@implementation czzImageDownloaderManager



+ (instancetype)sharedManager
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
