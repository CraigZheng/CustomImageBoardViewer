//
//  czzImageDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 delegate that notify a download has been finished - or failed
 */
@protocol czzImageDownloaderDelegate <NSObject>
-(void)downloadFinished:(NSString*)imgURLString success:(BOOL)success isThumbnail:(BOOL)thumbnail saveTo:(NSString*)path;
@optional
-(void)downloadStarted:(NSString*)target;
@end

@interface czzImageDownloader : NSObject
@property NSString *imageURLString;
@property id<czzImageDownloaderDelegate> delegate;
@property BOOL isThumbnail;

-(id)init;
-(void)start;
-(void)stop;
@end
