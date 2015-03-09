//
//  czzJSONProcessor.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 6/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzJSONProcessor.h"
#import "czzThread.h"
#import "czzAppDelegate.h"

@interface czzJSONProcessor()
@property NSMutableArray *processedThreads;
@end

@implementation czzJSONProcessor
@synthesize processedThreads;
@synthesize delegate;

/*
 "id": "185934",
 "img": "2015-03-08/54fbc263e793f",
 "ext": ".jpg",
 "now": "2015-03-08(日)11:30:43",
 "userid": "Xr4haKp",
 "name": "ATM",
 "email": "",
 "title": "无标题",
 "content": "A岛安卓客户端领到假饼干的各位请注意：在手机的应用管理里清除A岛客户端的所有应用数据后重新领取饼干即可<br />\r\n现在限时开放领取饼干，请各位在此串回复领取饼干，禁止另开串，谢谢合作。",
 "admin": "1",
 "remainReplys": 2162,
 "replyCount": "2172",
 "replys":
 */

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
//        //page number data
//        [self updatePageNumberWithJsonDict:[parsedObjects objectForKey:@"page"]];
        //thread list data
//        NSArray* parsedThreadData = [[parsedObjects objectForKey:@"data"] objectForKey:@"threads"];
        for (NSDictionary *rawThreadData in parsedObjects) {
            czzThread *newThread = [[czzThread alloc] initWithJSONDictionaryV2:rawThreadData];
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
        [self updatePageNumberWithJsonDict:[self readFromJsonDictionary:parsedObjects withName:@"page"]];
        //thread and sub thread data
//        czzThread *parentThread = [[czzThread alloc] initWithJSONDictionary:[parsedObjects objectForKey:@"threads"]];
        czzThread *parentThread = [[czzThread alloc] initWithJSONDictionaryV2:parsedObjects];
        NSArray* parsedThreadData = [self readFromJsonDictionary:parsedObjects withName:@"replys"];
        for (NSDictionary *rawThreadData in parsedThreadData) {
            czzThread *newThread = [[czzThread alloc] initWithJSONDictionaryV2:rawThreadData];
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

/*
 page =     {
 page = 1;
 size = 5;
 title = "No.5366351";
 };

 */

@end
