//
//  czzBlacklistDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol czzBlacklistDownloaderDelegate <NSObject>
@optional
-(void)downloadSuccess:(BOOL)success result:(NSSet*)blacklistEntities;
@end

@interface czzBlacklistDownloader : NSObject
@property id<czzBlacklistDownloaderDelegate> delegate;
-(void)downloadBlacklist;
@end
