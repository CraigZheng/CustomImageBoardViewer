//
//  NSArray+Splitting.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "NSArray+Splitting.h"


// Copied from http://stackoverflow.com/questions/27208722/objective-c-split-an-array-into-two-separate-arrays-based-on-even-odd-indexes
@implementation NSArray (Splitting)

-(NSArray *)arraysBySplittingInto:(NSUInteger)N
{
    NSAssert(N > 0, @"N cant be less than 1");
    NSMutableArray *resultArrays = [@[] mutableCopy];
    for (NSUInteger i =0 ; i<N; ++i) {
        [resultArrays addObject:[@[] mutableCopy]];
    }
    
    [self enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        [resultArrays[idx% resultArrays.count] addObject:object];
    }];
    return resultArrays;
}
@end
