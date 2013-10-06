//
//  czzReply.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPost.h"

@implementation czzPost
@synthesize name, email,title, content, imgData;
-(NSData *)requestBody{
    @try {
        if ([self isReady]) {
            NSMutableData *requestData = [NSMutableData new];
            if (name){
                NSData *nameData = [[NSString stringWithFormat:@"&name=%@", name] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:nameData];
            }
            if (email){
                NSData *emailData = [[NSString stringWithFormat:@"&email=%@", email]
                                     dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:emailData];
            }
            if (title){
                NSData *titleData = [[NSString stringWithFormat:@"&title=%@", title]
                                     dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:titleData];
            }
            if (content){
                NSData *contentData = [[NSString stringWithFormat:@"&content=%@", content] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:contentData];
            }
            if (imgData){
                //TODO: ready the image data in reqeust
            }
            return requestData;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    return nil;
}

-(BOOL)isReady{
    if (self.content.length != 0 || self.imgData != nil)
        return YES;
    return NO;
}
@end
