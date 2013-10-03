//
//  czzXMLDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol czzXMLDownloaderDelegate <NSObject>
@optional
-(void)downloadOf:(NSURL*)xmlURL successed:(BOOL)successed result:(NSData*)xmlData;
@end

@interface czzXMLDownloader : NSObject<NSURLConnectionDelegate>
@property (nonatomic) NSURL *targetURL;
@property id<czzXMLDownloaderDelegate>  delegate;

-(id)initWithTargetURL:(NSURL*)url delegate:(id<czzXMLDownloaderDelegate>)delegate startNow:(BOOL)now;
-(void)start;
-(void)stop;
@end
