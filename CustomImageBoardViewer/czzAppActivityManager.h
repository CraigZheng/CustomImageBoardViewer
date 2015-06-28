//
//  czzAppActivityManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//
#define AppActivityManager [czzAppActivityManager sharedManager]

#import <Foundation/Foundation.h>


@interface czzAppActivityManager : NSObject

+(instancetype)sharedManager;
@end
