//
//  czzBlacklistSender.m
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzBlacklistSender.h"
#import "czzXMLDownloader.h"
#import "SMXMLDocument.h"
#import "czzBlacklist.h"
#import "czzAppDelegate.h"
#import "czzBlacklistDownloader.h"

@interface czzBlacklistSender()<NSURLConnectionDelegate, czzBlacklistDownloaderDelegate>
@property NSURLConnection *urlConn;
@property NSMutableData *receivedResponse;
@end

@implementation czzBlacklistSender
@synthesize blacklistEntity;
@synthesize urlConn;
@synthesize targetURLString;
@synthesize receivedResponse;

-(id)init{
    self = [super init];
    if (self){
        //targetURLString = @"http://civ.my-realm.com/php/update_blacklist.php";
        targetURLString = [[czzAppDelegate sharedAppDelegate].myhost stringByAppendingPathComponent:@"php/update_blacklist.php"];
    }
    return  self;
}

-(void)sendBlacklistUpdate{
    if ([blacklistEntity isReady]){
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:targetURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:blacklistEntity.requestBody];
        urlConn = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        [urlConn start];
    }
}

#pragma NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    receivedResponse = [NSMutableData new];
    NSDictionary *dict = [(NSHTTPURLResponse*)response allHeaderFields];
    for (NSString *header in dict) {
        //NSLog(@"%@:%@", header, [dict objectForKey:header]);
    }
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
        BOOL success = NO;
        NSString *message = @"";
        for (SMXMLElement *child in xmlDoc.root.children){
            if ([child.name isEqualToString:@"Success"]){
                success = [child.value boolValue];
            }
            if ([child.name isEqualToString:@"Message"]){
                message = child.value;
            }
        }
        //inform the delegate
        if ([self.delegate respondsToSelector:@selector(statusReceived:message:)])
        {
            [self.delegate statusReceived:success message:message];
        }
        //refresh the blacklist
        czzBlacklistDownloader *blacklistDownloader = [czzBlacklistDownloader new];
        blacklistDownloader.delegate = self;
        [blacklistDownloader downloadBlacklist];
    }
}

#pragma czzBlacklistDownloader delegate
-(void)downloadSuccess:(BOOL)success result:(NSSet *)blacklistEntities{
    if (success){
        [[czzBlacklist sharedInstance] setBlacklistEntities:blacklistEntities];
    }
}

@end
