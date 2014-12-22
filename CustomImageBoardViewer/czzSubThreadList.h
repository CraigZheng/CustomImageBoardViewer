//
//  czzSubThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define SUB_THREAD_LIST_CACHE_FILE @"_cache.dat"

#import "czzThreadList.h"

@interface czzSubThreadList : czzThreadList
@property NSString* parentID;
@property (nonatomic) czzThread *parentThread;
@property BOOL restoredFromCache;

-(instancetype)initWithParentThread:(czzThread*)thread;
@end
