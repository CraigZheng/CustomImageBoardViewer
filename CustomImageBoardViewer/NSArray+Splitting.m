//
//  NSArray+Splitting.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/12/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "NSArray+Splitting.h"

@implementation NSArray (Splitting)

-(NSArray *)arraysBySplittingWithSize:(NSUInteger)size
{
    NSAssert(size > 0, @"N cant be less than 1");
    
    NSMutableArray *arrays = [NSMutableArray new];
    CGFloat pages = (double)self.count / size;
    if (pages >= 1) {
        for (NSInteger i = 0; i < ceil(pages); i++) {
            NSInteger start = i * size;
            NSInteger length = size;
            if (start + length > self.count) {
                length -= start + length - self.count;
            }
            [arrays addObject:[self subarrayWithRange:NSMakeRange(start, length)]];
        }
    } else {
        return @[self];
    }
    return arrays;
}
@end
