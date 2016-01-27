//
//  czzBlacklistEntity.m
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzBlacklistEntity.h"

@implementation czzBlacklistEntity

-(BOOL)isReady{
    if (self.threadID) {
        return YES;
    }
    return NO;
}

-(NSData *)requestBody{
    if ([self isReady]){
        NSMutableData *body = [NSMutableData new];
        if (self.threadID){
            NSData *threadData = [[NSString stringWithFormat:@"&threadID=%ld", (long)self.threadID] dataUsingEncoding:NSUTF8StringEncoding];
            [body appendData:threadData];
        }
        if (self.reason){
            NSData *reasonData = [[NSString stringWithFormat:@"&reason=%@", self.reason] dataUsingEncoding:NSUTF8StringEncoding];
            [body appendData:reasonData];
        }
        if (self.content){
            NSData *contentData = [[NSString stringWithFormat:@"&content=%d", 1] dataUsingEncoding:NSUTF8StringEncoding];
            [body appendData:contentData];
        }
        if (self.block){
            NSData *blockData = [[NSString stringWithFormat:@"&block=%d", 1] dataUsingEncoding:NSUTF8StringEncoding];
            [body appendData:blockData];
        }
        if (self.image){
            NSData *imageData = [[NSString stringWithFormat:@"&image=%d", 1] dataUsingEncoding:NSUTF8StringEncoding];
            [body appendData:imageData];
        }
        //DDLogDebug(@"%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
        return body;
    }
    return  nil;
}

#pragma mark - hash and isEqual, two entities with same threadID is consider equal
-(NSUInteger)hash{
    return self.threadID;
}

-(BOOL)isEqual:(id)object{
    if (((czzBlacklistEntity*)object).threadID == self.threadID)
        return YES;
    return NO;
}
@end
