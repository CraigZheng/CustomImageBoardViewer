//
//  czzFavouriteManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 23/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define favouriteManager [czzFavouriteManager sharedInstance]
#define FAVOURITE_THREAD_CACHE_FILE @"favourites.dat"

#import "czzThread.h"
#import <Foundation/Foundation.h>

@interface czzFavouriteManager : NSObject
@property NSMutableOrderedSet *favouriteThreads;
@property NSMutableArray *verticalHeights;
@property NSMutableArray *horizontalHeights;

-(void)addFavourite:(czzThread*)thread;
-(BOOL)removeFavourite:(czzThread*)thread;
-(void)removeAll;
-(void)saveCurrentState;
+(instancetype)sharedInstance;
@end
