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
        DLog(@"%@", error);
        if (delegate) {
            if ([delegate respondsToSelector:@selector(threadListProcessed:::)]) {
                [delegate threadListProcessed:self :nil :NO];
            } else if ([delegate respondsToSelector:@selector(threadListProcessed::)]) {
                [delegate threadListProcessed:nil :NO];
            }
        }
    }
    @try {
        //page number data
        [self updatePageNumberWithJsonDict:[parsedObjects objectForKey:@"page"]];
        //thread list data
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
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
        if (delegate) {
            if ([delegate respondsToSelector:@selector(threadListProcessed:::)]) {
                [delegate threadListProcessed:self :nil :NO];
            } else if ([delegate respondsToSelector:@selector(threadListProcessed::)]) {
                [delegate threadListProcessed:nil :NO];
            }
        }
    }
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
        DLog(@"%@", error);
        if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
            [delegate subThreadProcessedForThread:nil :nil :NO];
        }
    }
    @try {
        //page number data
        [self updatePageNumberWithJsonDict:[parsedObjects objectForKey:@"page"]];
        //thread and sub thread data
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
    @catch (NSException *exception) {
        DLog(@"%@", exception);
        if (delegate) {
            if ([delegate respondsToSelector:@selector(subThreadProcessedForThread::::)]) {
                [delegate subThreadProcessedForThread:self :nil :nil :NO];
            } else if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
                [delegate subThreadProcessedForThread:nil :nil :NO];
            }
        }
    }
}

-(void)updatePageNumberWithJsonDict:(NSDictionary*)jsonDict {
    //if jsonDict or delegate is empty
    if (!jsonDict || !delegate)
        return;
    //check if dictionary has the following 2 keys
    if ([jsonDict valueForKey:@"page"] && [jsonDict valueForKey:@"size"])
    {
        NSInteger pageNumber = [[self readFromJsonDictionary:jsonDict withName:@"page"] integerValue];
        NSInteger totalPages = [[self readFromJsonDictionary:jsonDict withName:@"size"] integerValue];
        if ([delegate respondsToSelector:@selector(pageNumberUpdated:inAllPage:)])
            [delegate pageNumberUpdated:pageNumber inAllPage:totalPages];
    }
}

-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name {
    if ([[dict valueForKey:name] isEqual:[NSNull null]]) {
        return nil;
    }
    id value = [dict valueForKey:name];
    return value;
}
/*
 page =     {
 page = 1;
 size = 5;
 title = "No.5366351";
 };

 */

@end
