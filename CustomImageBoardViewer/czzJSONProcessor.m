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
        if (delegate)
            [delegate threadListProcessed:nil :NO];
    }
    NSArray* parsedThreadData = [[parsedObjects objectForKey:@"data"] objectForKey:@"threads"];
    for (NSDictionary *rawThreadData in parsedThreadData) {
        czzThread *newThread = [[czzThread alloc] initWithJSONDictionary:rawThreadData];
        [processedThreads addObject:newThread];
    }
    if (delegate)
        [delegate threadListProcessed:processedThreads :YES];

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
        if (delegate)
            [delegate subThreadProcessed:nil :NO];
    }
    NSArray* parsedThreadData = [parsedObjects objectForKey:@"replys"];
    for (NSDictionary *rawThreadData in parsedThreadData) {
        czzThread *newThread = [[czzThread alloc] initWithJSONDictionary:rawThreadData];
        [processedThreads addObject:newThread];
    }
    if (delegate)
        [delegate subThreadProcessed:processedThreads :YES];

}

@end
