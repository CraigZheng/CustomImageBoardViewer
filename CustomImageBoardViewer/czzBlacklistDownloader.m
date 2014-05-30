//
//  czzBlacklistDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzBlacklistEntity.h"
#import "czzBlacklistDownloader.h"
#import "SMXMLDocument.h"
#import "czzAppDelegate.h"

@interface czzBlacklistDownloader()<NSURLConnectionDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedResponse;
@property NSString *targetURLString;
@end

@implementation czzBlacklistDownloader
@synthesize urlConn;
@synthesize receivedResponse;
@synthesize targetURLString;

-(id)init{
    self = [super init];
    if (self){
        //targetURLString = @"http://civ.my-realm.com/php/download_blacklist.php";
        targetURLString = [[czzAppDelegate sharedAppDelegate].myhost stringByAppendingPathComponent:@"php/download_blacklist.php"];
    }
    return self;
}

-(void)downloadBlacklist{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:targetURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}


#pragma NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedResponse = [NSMutableData new];
    //NSDictionary *dict = [(NSHTTPURLResponse*)response allHeaderFields];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedResponse appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self response:receivedResponse];
}

#pragma Decode the self.response xml data
-(void)response:(NSData*)xmlData{
    SMXMLDocument *xmlDoc = [[SMXMLDocument alloc]initWithData:xmlData error:nil];
    if (xmlDoc){
        NSMutableSet *blacklistEntities = [NSMutableSet new];
        BOOL success = NO;
        for (SMXMLElement *child in xmlDoc.root.children){
            if ([child.name isEqualToString:@"Success"]){
                success = [child.value boolValue];
            }
            if ([child.name isEqualToString:@"Threads"]){
                for (SMXMLElement *thread in child.children) {
                    czzBlacklistEntity *blacklistEntity = [czzBlacklistEntity new];
                    for (SMXMLElement *threadChild in thread.children) {
                        if ([threadChild.name isEqualToString:@"ID"]){
                            blacklistEntity.ID = [threadChild.value integerValue];
                        }
                        else if ([threadChild.name isEqualToString:@"ThreadID"]){
                            blacklistEntity.threadID = [threadChild.value integerValue];
                        }
                        else if ([threadChild.name isEqualToString:@"Date"]){
                            NSDateFormatter *dateFormatter = [NSDateFormatter new];
                            [dateFormatter setDateFormat:@"Y-m-d H:i:s"];
                            blacklistEntity.date = [dateFormatter dateFromString:threadChild.value];
                        }
                        else if ([threadChild.name isEqualToString:@"Reason"]){
                            blacklistEntity.reason = threadChild.value;
                        }
                        else if ([threadChild.name isEqualToString:@"Content"]){
                            blacklistEntity.content = [threadChild.value boolValue];
                        }
                        else if ([threadChild.name isEqualToString:@"Image"]){
                            blacklistEntity.image = [threadChild.value boolValue];
                        }
                        else if ([threadChild.name isEqualToString:@"Harmful"]){
                            blacklistEntity.harmful = [threadChild.value boolValue];
                        }
                        else if ([threadChild.name isEqualToString:@"Block"]){
                            blacklistEntity.block = [threadChild.value boolValue];
                        }
                    }
                    if (blacklistEntity.threadID > 0)
                        [blacklistEntities addObject:blacklistEntity];

                }
            }
        }
        //inform the delegate
        if ([self.delegate respondsToSelector:@selector(downloadSuccess:result:)])
        {
            [self.delegate downloadSuccess:success result:blacklistEntities];
        }
    }
}
@end
