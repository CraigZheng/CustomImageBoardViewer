//
//  czzNotificationManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzNotificationManager : NSObject
@property (nonatomic) NSString *cachePath;

-(void)saveNotifications:(NSMutableOrderedSet*)notifications;
-(NSMutableOrderedSet*)checkCachedNotifications;
-(void)removeNotifications;

@end
