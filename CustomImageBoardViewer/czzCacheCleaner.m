//
//  czzCacheCleaner.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzCacheCleaner.h"

#import "NSFileManager+Util.h"
#import "czzAppDelegate.h"

@implementation czzCacheCleaner

-(instancetype)init {
    self = [super init];
    if (self) {
        if (settingCentre.userDefShouldCleanCaches) {
            [self checkAndClean];
        }
    }
    return self;
}

-(void)checkAndClean {
    NSArray *cacheFolders = @[[czzAppDelegate imageFolder], [czzAppDelegate thumbnailFolder], [czzAppDelegate threadCacheFolder]];
    
    
    NSDateComponents *components= [[NSDateComponents alloc] init];
//    components.month = -1; // 1 month eariler.
    components.weekOfMonth = -1;
    NSDate *aMonthAgo = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateByAddingComponents:components toDate:[NSDate new] options:0];
    
    NSDateFormatter *debugDateFormatter = [NSDateFormatter new];
    debugDateFormatter.dateFormat = @"yyyy-MM-dd";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (NSString *folderPath in cacheFolders) {
            for (NSURL *fileURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:folderPath] includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:0 error:nil]) {
                NSDate *fileCreationDate;
                [fileURL getResourceValue:&fileCreationDate forKey:NSURLContentModificationDateKey error:nil];
                if ([fileCreationDate compare:aMonthAgo] == NSOrderedAscending) {
                }
                
            }
        }
    });
    
}

+(instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}
@end
