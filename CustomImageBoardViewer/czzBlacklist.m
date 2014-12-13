//
//  czzBlacklist.m
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzBlacklist.h"

@implementation czzBlacklist
@synthesize blacklistEntities;
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

-(czzBlacklistEntity *)blacklistEntityForThreadID:(NSInteger)threadID{
    @try {
        NSPredicate *threadIDPredicate = [NSPredicate predicateWithFormat:@"threadID == %d", threadID];
        NSSet *set = [blacklistEntities filteredSetUsingPredicate:threadIDPredicate];
        return set.anyObject;
        //return [blacklistEntities filteredSetUsingPredicate:threadIDPredicate].anyObject;

    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return nil;
}
@end
