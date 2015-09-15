//
//  czzNotificationDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol czzNotificationDownloaderDelegate <NSObject>
-(void)notificationDownloaded:(NSArray*)notifications;

@end

@interface czzNotificationDownloader : NSObject
@property (strong, nonatomic) NSString *notificationFile;
@property czzURLDownloader *urlDownloader;
@property (weak, nonatomic) id<czzNotificationDownloaderDelegate> delegate;

-(void)downloadNotificationWithVendorID:(NSString*)vendorID;
@end
