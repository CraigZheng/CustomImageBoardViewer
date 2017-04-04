//
//  NSArray+Splitting.h
//  CustomImageBoardViewer
//
//  Created by Craig on 28/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzThread.h"

@interface NSArray (Splitting)
-(NSArray *)arraysBySplittingWithSize:(NSUInteger)size;
@end

@interface NSArray<czzThread> (RemovingThreads)
- (NSArray<czzThread> *)arrayByRemovingThreadsWithID:(NSInteger)threadID;

@end
