//
//  czzThreadCache.h
//  CustomImageBoardViewer
//
//  Created by Craig on 25/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzThread;
@interface czzThreadCacheManager : NSObject
+ (id)sharedInstance;

-(BOOL)saveThreads:(NSArray*)threads;
-(NSArray*)readThreads:(czzThread*)parentThread;
-(void)removeThreadCache:(czzThread*)thread;
-(void)removeAllThreadCache;
-(NSString*)totalSize;
@end
