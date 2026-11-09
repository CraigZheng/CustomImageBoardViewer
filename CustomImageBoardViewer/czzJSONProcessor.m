//
//  czzJSONProcessor.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 6/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzJSONProcessor.h"
#import "czzThread.h"
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"
#import "NSDictionary+Util.h"

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

-(void)processThreadListFromData:(NSData *)jsonData forForum:(czzForum*)forum{
    processedThreads = [NSMutableArray new];
    NSError *error;
    id parsedObjects;
    if (jsonData)
        parsedObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

    // Bail out with a single, shared failure path if the data cannot be used at all.
    NSString *failureReason = [self failureReasonForThreadListData:jsonData parsedObjects:parsedObjects error:error];
    if (failureReason) {
        DDLogDebug(@"%@", failureReason);
        [self notifyThreadListProcessed:NO];
        return;
    }

    @try {
        //thread list data
        for (NSDictionary *rawThreadData in (NSArray *)parsedObjects) {
            czzThread *newThread = [[czzThread alloc] initWithJSONDictionary:rawThreadData];
            if (newThread) {
                [processedThreads addObject:newThread];
            }
        }
        [self notifyThreadListProcessed:YES];
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
        [self notifyThreadListProcessed:NO];
    }
}

// Returns nil when the JSON data can be processed, otherwise a human readable reason why not.
-(NSString *)failureReasonForThreadListData:(NSData *)jsonData parsedObjects:(id)parsedObjects error:(NSError *)error {
    if (!jsonData) {
        return @"Empty data!";
    }
    if (error) {
        return error.localizedDescription ?: @"Failed to parse JSON.";
    }
    // Some APIs return an error envelope (e.g. {"success":false,"error":"..."}), which parses into
    // an NSDictionary instead of the expected NSArray of threads. Treat that as a failure instead of
    // fast-enumerating the dictionary's keys as if they were threads.
    if ([parsedObjects isKindOfClass:[NSDictionary class]]) {
        NSString *serverErrorMessage = [(NSDictionary *)parsedObjects objectForKey:@"error"];
        if ([serverErrorMessage isKindOfClass:[NSString class]]) {
            return serverErrorMessage;
        }
        return [NSString stringWithFormat:@"Expected an array of threads, got a dictionary: %@", parsedObjects];
    }
    if (![parsedObjects isKindOfClass:[NSArray class]]) {
        return [NSString stringWithFormat:@"Unexpected parsed object type: %@", [parsedObjects class]];
    }
    return nil;
}

-(void)notifyThreadListProcessed:(BOOL)success {
    if (!delegate) {
        return;
    }
    NSArray *newThreads = success ? processedThreads : nil;
    if ([delegate respondsToSelector:@selector(threadListProcessed:::)]) {
        [delegate threadListProcessed:self :newThreads :success];
    } else if ([delegate respondsToSelector:@selector(threadListProcessed::)]) {
        [delegate threadListProcessed:newThreads :success];
    }
}

-(void)processSubThreadFromData:(NSData *)jsonData forForum:(czzForum *)forum{
    processedThreads = [NSMutableArray new];
    NSError *error;
    NSDictionary *parsedObjects;
    if (jsonData)
        parsedObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else
        error = [NSError errorWithDomain:@"Empty Data!" code:999 userInfo:nil];
    if (error) {
        DDLogDebug(@"%@", error);
        if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
            [delegate subThreadProcessedForThread:nil :nil :NO];
        } else {
            [delegate subThreadProcessedForThread:self :nil :nil :NO];
        }
    }
    @try {
        //        if (forum.parserType == FORUM_PARSER_AISLE) {
        //thread and sub thread data
        czzThread *parentThread = [[czzThread alloc] initWithJSONDictionary:parsedObjects];
        NSArray* parsedThreadData = [parsedObjects jsonValueWithKey:@"Replies"];
        for (NSDictionary *rawThreadData in parsedThreadData) {
            czzThread *newThread = [[czzThread alloc] initWithJSONDictionary:rawThreadData];
            if (newThread) {
                [processedThreads addObject:newThread];
            }
        }
        
        if (delegate) {
            if ([delegate respondsToSelector:@selector(subThreadProcessedForThread::::)]) {
                [delegate subThreadProcessedForThread:self :parentThread :processedThreads :YES];
            } else if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
                [delegate subThreadProcessedForThread:parentThread :processedThreads :YES];
            }
        }
        //        } else if (forum.parserType == FORUM_PARSER_BT_ISLE) {
        //            //TODO: add parser for A dao parser type
        //        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
        if (delegate) {
            if ([delegate respondsToSelector:@selector(subThreadProcessedForThread::::)]) {
                [delegate subThreadProcessedForThread:self :nil :nil :NO];
            } else if ([delegate respondsToSelector:@selector(subThreadProcessedForThread:::)]) {
                [delegate subThreadProcessedForThread:nil :nil :NO];
            }
        }
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
