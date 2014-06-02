//
//  czzNotificationManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotificationManager.h"

@implementation czzNotificationManager

#pragma mark - save and restore notifications
-(void)saveNotifications:(NSMutableOrderedSet*)notifications {
    if (notifications.count > 0)
    {
        [NSKeyedArchiver archiveRootObject:notifications toFile:[self.cachePath stringByAppendingPathComponent:@"Notifications.cac"]];
    }
}

-(void)removeNotifications {
    [[NSFileManager defaultManager] removeItemAtPath:[self.cachePath stringByAppendingPathComponent:@"Notifications.cac"] error:nil];
}

-(NSString *)cachePath {
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cachePath = [libraryPath stringByAppendingPathComponent:@"NotificationCache"];
    return cachePath;
}

-(NSMutableOrderedSet*)checkCachedNotifications {
    NSMutableOrderedSet *cachedNotification = [NSKeyedUnarchiver unarchiveObjectWithFile:[self.cachePath stringByAppendingPathComponent:@"Notifications.cac"]];
    return cachedNotification;
}

@end
