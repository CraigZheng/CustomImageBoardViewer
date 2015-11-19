//
//  czzWKThreadViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

#import "czzWKThread.h"

#define wkThreadViewControllerIdentifier @"czzWKThreadViewController"

@interface czzWKThreadInterfaceController : WKInterfaceController

@property (nonatomic, strong) czzWKThread *wkThread;
@end
