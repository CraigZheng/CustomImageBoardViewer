//
//  czzXMLProcessor.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/03/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzXMLProcessor.h"
#import "czzAppDelegate.h"
#import "czzThread.h"
#import "SMXMLDocument.h"

@implementation czzXMLProcessor

-(void)processThreadListFromData:(NSData *)xmlData{
    NSMutableArray *newThreads = [NSMutableArray new];
    NSError *error;
    SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
    if (error){
        if ([self.delegate respondsToSelector:@selector(threadListProcessed::)]){
            [self.delegate threadListProcessed:nil :NO];
        }
        NSLog(@"%@", error);
    }
    @try {
        for (SMXMLElement *child in xmlDoc.root.children) {
            if ([child.name isEqualToString:@"model"]){
                //create a thread outta this xml data
                czzThread *thread = [[czzThread alloc] initWithSMXMLElement:child];
                if (thread.ID != 0) {
                    [newThreads addObject:thread];
                }
            }
            if ([child.name isEqualToString:@"access_token"]){
                //if current access_token is nil
                NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
                if (!oldToken){
                    [[NSUserDefaults standardUserDefaults] setObject:child.value forKey:@"access_token"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            //my message
            if ([child.name isEqualToString:@"privateMessage"]){
                NSString *title;
                NSString *message;
                NSInteger howLong = 1.5;
                BOOL shouldAlwaysDisplay = NO;
                for (SMXMLElement *childNode in child.children){
                    if ([childNode.name isEqualToString:@"title"]){
                        title = childNode.value;
                    }
                    if ([childNode.name isEqualToString:@"message"]){
                        message = childNode.value;
                    }
                    if ([childNode.name isEqualToString:@"howLong"]){
                        if ([childNode.value integerValue] > 0)
                            howLong = [childNode.value integerValue];
                    }
                    if ([childNode.name isEqualToString:@"shouldAlwaysDisplay"]){
                        shouldAlwaysDisplay = [childNode.value boolValue];
                    }
                }
                if (![[NSUserDefaults standardUserDefaults] objectForKey:@"firstTimeRunning"] || shouldAlwaysDisplay)
                    if ([self.delegate respondsToSelector:@selector(messageProcessed:::)]){
                        [self.delegate messageProcessed:title :message :howLong];
                    }
            }
        }
        if ([self.delegate respondsToSelector:@selector(threadListProcessed::)])
        {
            if (newThreads.count > 0){
                [self.delegate threadListProcessed:newThreads :YES];
            }
        }
    }
    @catch (NSException *exception) {
        if ([self.delegate respondsToSelector:@selector(threadListProcessed::)]){
            [self.delegate threadListProcessed:nil :NO];
        }
    }
}

-(void)processSubThreadFromData:(NSData *)xmlData{
    NSMutableArray *newThreads = [NSMutableArray new];
    
    NSError *error;
    SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
    if (error){
        if ([self.delegate respondsToSelector:@selector(subThreadProcessed::)])
            [self.delegate subThreadProcessed:nil :NO];
        NSLog(@"%@", error);
    }
    for (SMXMLElement *child in xmlDoc.root.children) {
        if ([child.name isEqualToString:@"model"]){
            //create a thread outta this xml data
            czzThread *thread = [[czzThread alloc] initWithSMXMLElement:child];
            if (thread.ID != 0)
                [newThreads addObject:thread];
        }
        if ([child.name isEqualToString:@"access_token"]){
            //if current access_token is nil
            NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
            if (!oldToken){
                [[NSUserDefaults standardUserDefaults] setObject:child.value forKey:@"access_token"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
    if ([self.delegate respondsToSelector:@selector(subThreadProcessed::)])
        [self.delegate subThreadProcessed:newThreads :YES];
}
@end
