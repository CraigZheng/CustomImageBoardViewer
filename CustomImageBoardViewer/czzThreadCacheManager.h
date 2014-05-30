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
@property NSString *cachePath;

+ (id)sharedInstance;

-(BOOL)saveContentOffSetForHome:(CGPoint)contentOffSet;
-(CGPoint)readContentOffSetForHome;
-(void)removeContentOffSetForHome;
-(BOOL)saveSelectedThreadForHome:(czzThread*)selectedThread;
-(czzThread*)readSelectedThreadForHome;
-(void)removeSelectedThreadForHome;
-(BOOL)saveThreadsForHome:(NSArray*)threads;
-(NSArray*)readThreadsForHome;
-(void)removeThreadsForHome;
-(BOOL)saveThreads:(NSArray*)threads forThread:(czzThread*)parentThread;
-(NSArray*)readThreads:(czzThread*)parentThread;
-(BOOL)saveHeights:(NSArray*)heights ForThread:(czzThread*)parentThread;
-(NSArray*)readHeightsForThread:(czzThread*)parentThread;
-(void)removeThreadCache:(czzThread*)thread;
-(void)removeAllThreadCache;
-(NSString*)totalSize;
@end
