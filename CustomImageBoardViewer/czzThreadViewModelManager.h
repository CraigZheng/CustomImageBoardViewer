//
//  czzSubThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define SUB_THREAD_LIST_CACHE_FILE @"_cache.dat"

#import "czzHomeViewModelManager.h"

@interface czzThreadViewModelManager : czzHomeViewModelManager
@property NSString* parentID;
@property (nonatomic) czzThread *parentThread;
@property BOOL restoredFromCache;

-(instancetype)initWithParentThread:(czzThread*)thread andForum:(czzForum*)forum;
-(instancetype)restoreWithFile:(NSString*)filePath;
@end
