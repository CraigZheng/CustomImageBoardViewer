//
//  czzJSONProcessor.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 6/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzJSONProcessor.h"
#import "czzThread.h"

@interface czzJSONProcessor()
@property NSMutableArray *processedThreads;
@end

@implementation czzJSONProcessor
@synthesize processedThreads;
@synthesize delegate;

-(void)processThreadListFromData:(NSData *)jsonData {
    processedThreads = [NSMutableArray new];
    NSError *error;
    NSDictionary *parsedObjects;
    if (jsonData)
        parsedObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else
        error = [NSError errorWithDomain:@"Empty Data!" code:999 userInfo:nil];
    if (error) {
        NSLog(@"%@", error);
        if (delegate) {
            if ([delegate respondsToSelector:@selector(threadListProcessed:::)]) {
                [delegate threadListProcessed:self :nil :NO];
            } else if ([delegate respondsToSelector:@selector(threadListProcessed::)]) {
                [delegate threadListProcessed:nil :NO];
            }
        }
    }
    NSArray* parsedThreadData = [[parsedObjects objectForKey:@"data"] objectForKey:@"threads"];
    for (NSDictionary *rawThreadData in parsedThreadData) {
        czzThread *newThread = [[czzThread alloc] initWithJSONDictionary:rawThreadData];
        if (newThread)
            [processedThreads addObject:newThread];
    }
    if (delegate) {
        if ([delegate respondsToSelector:@selector(threadListProcessed:::)]) {
            [delegate threadListProcessed:self :processedThreads :YES];
        } else if ([delegate respondsToSelector:@selector(threadListProcessed::)]) {
            [delegate threadListProcessed:processedThreads :YES];
        }
    }
    NSLog(@"");
}

-(void)processSubThreadFromData:(NSData *)jsonData {
    processedThreads = [NSMutableArray new];
    NSError *error;
    NSDictionary *parsedObjects;
    if (jsonData)
        parsedObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else
        error = [NSError errorWithDomain:@"Empty Data!" code:999 userInfo:nil];
    if (error) {
        NSLog(@"%@", error);
        if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
            [delegate subThreadProcessedForThread:nil :nil :NO];
        }
    }
    czzThread *parentThread = [[czzThread alloc] initWithJSONDictionary:[parsedObjects objectForKey:@"threads"]];
    NSArray* parsedThreadData = [parsedObjects objectForKey:@"replys"];
    for (NSDictionary *rawThreadData in parsedThreadData) {
        czzThread *newThread = [[czzThread alloc] initWithJSONDictionary:rawThreadData];
        [processedThreads addObject:newThread];
    }
    
    if (delegate) {
        if ([delegate respondsToSelector:@selector(subThreadProcessedForThread::::)]) {
            [delegate subThreadProcessedForThread:self :parentThread :processedThreads :YES];
        } else if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
            [delegate subThreadProcessedForThread:parentThread :processedThreads :YES];
        }
    }

}

@end
