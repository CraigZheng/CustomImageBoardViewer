//
//  czzReply.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPost.h"

@implementation czzPost
@synthesize name, email,title, content, imgData, access_token;

//during the initialisation, init the access token with data from the last time
-(id)init{
    self = [super init];
    if (self){
        NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
        if (oldToken)
            access_token = oldToken;
    }
    return self;
}

-(NSData *)requestBody{
    @try {
        if ([self isReady]) {
            NSMutableData *requestData = [NSMutableData new];
            //init the access_token from file

            if (access_token){
                NSData *access_token_data = [[NSString stringWithFormat:@"&access_token=%@", access_token] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:access_token_data];
            }
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

-(void)saveAccessToken{
    if (access_token)
    {
        [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
@end
