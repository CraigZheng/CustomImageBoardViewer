//
//  czzSubThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzSubThreadList.h"


@implementation czzSubThreadList
@synthesize parentID;
@synthesize parentThread;
@synthesize baseURLString;


-(instancetype)initWithParentThread:(czzThread *)thread {
    self = [super init];
    if (self) {
        parentThread = thread;
        parentID = [NSString stringWithFormat:@"%ld", (long) parentThread.ID];
        baseURLString = [[settingCentre thread_content_host] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", parentID]];
    }
    
    return self;
}


@end
