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
@property (strong, nonatomic) NSString* parentID;
@property (strong, nonatomic) czzThread *parentThread;
@property (assign, nonatomic) BOOL restoredFromCache;
@property (strong, nonatomic) NSString *selectedUserToHighlight;


- (void)reset;
-(instancetype)initWithParentThread:(czzThread*)thread andForum:(czzForum*)forum;
-(instancetype)restoreWithFile:(NSString*)filePath;
@end
