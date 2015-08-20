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
@synthesize parentID, forumName;
@synthesize forumID;

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

-(NSMutableData *)makeRequestBody{
    @try {
        if ([self isReady]) {
            
            NSString *boundary = @"-0-x-K-h-T-m-L-b-O-u-N-d-A-r-Y-";
            NSMutableData *body = [NSMutableData new];
            
            NSMutableDictionary *params = [NSMutableDictionary new];
            
            NSMutableData *requestData = [NSMutableData new];
            //init the access_token from file
            if (forumName && forumName.length > 0){
                [params setObject:forumName forKey:@"forumName"];
                
                NSData *forumData = [[NSString stringWithFormat:@"&forumName=%@", forumName] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:forumData];
            }
            if (forumID && forumID.length > 0) {
                [params setObject:forumID forKey:@"fid"];
                
                NSData *forumIDData = [[NSString stringWithFormat:@"&fid=%@", forumID] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:forumIDData];
            }
            if (parentID > 0){
                [params setObject:[NSString stringWithFormat:@"%ld", (long)parentID] forKey:@"resto"];
                
                NSString *parentIDPara = [NSString stringWithFormat:@"&resto=%ld", (long)parentID];
                [requestData appendData:[parentIDPara dataUsingEncoding:NSUTF8StringEncoding]];
            }
            if (access_token){
                [params setObject:access_token forKey:@"access_token"];
                
                NSData *access_token_data = [[NSString stringWithFormat:@"&access_token=%@", access_token] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:access_token_data];
                
            }
            if (name && name.length > 0){
                [params setObject:name forKey:@"name"];

                
                NSData *nameData = [[NSString stringWithFormat:@"&name=%@", name] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:nameData];
                
            }
            if (email && email.length > 0){
                [params setObject:email forKey:@"email"];

                
                NSData *emailData = [[NSString stringWithFormat:@"&email=%@", email]
                                     dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:emailData];
                
            }
            if (title && title.length > 0){
                [params setObject:title forKey:@"title"];

                
                NSData *titleData = [[NSString stringWithFormat:@"&title=%@", title]
                                     dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:titleData];
                 
            }
            if (content && content.length > 0){
                [params setObject:content forKey:@"content"];

                NSData *contentData = [[NSString stringWithFormat:@"&content=%@", content] dataUsingEncoding:NSUTF8StringEncoding];
                [requestData appendData:contentData];
            }
        
            if (imgData){
                for (NSString *key in params.allKeys) {
                    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[[NSString stringWithFormat:@"%@\r\n", [params objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
                    
                }

                [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:imgData];
                [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                //if has image data, return this body instead
                return body;
            }
            //regular return without image data
            return requestData;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
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

-(NSString*)stringWithContentsOfBinaryData:(NSData*) data{
    NSUInteger capacity = [data length] * 2;
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = [data bytes];
    NSInteger i;
    for (i=0; i<[data length]; ++i) {
        [stringBuffer appendFormat:@"%02X", (NSUInteger)dataBuffer[i]];
    }
    
    return stringBuffer;
}
@end
