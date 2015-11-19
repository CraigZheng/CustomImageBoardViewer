//
//  czzWatchKitHomeRowController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WatchKit/WatchKit.h>

#import "czzWKThread.h"

#define wkHomeViewRowControllerIdentifier @"wkHomeViewRow"

@interface czzWatchKitHomeRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *wkThreadContentLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *wkThreadInformationLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *wkThreadImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *wkThreadThumbnailImage;

@property (strong, nonatomic) czzWKThread *wkThread;
@end
