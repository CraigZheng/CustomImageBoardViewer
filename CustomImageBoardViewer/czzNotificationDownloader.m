//
//  czzNotificationDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotificationDownloader.h"
#import "czzAppDelegate.h"
#import "czzNotification.h"
#import "SMXMLDocument.h"

@interface czzNotificationDownloader()<NSURLConnectionDataDelegate>
@property NSMutableData *receivedData;

@end

@implementation czzNotificationDownloader
@synthesize notificationFile;
@synthesize urlConn;
@synthesize receivedData;
@synthesize delegate;

-(id)init {
    self = [super init];
    if (self) {
        notificationFile = @"notifications.php";
    }
    return self;
}

-(void)downloadNotificationWithVendorID:(NSString *)vendorID {
    NSString *targetURLString = [[czzAppDelegate sharedAppDelegate].myhost stringByAppendingPathComponent:notificationFile];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:targetURLString]];
    
    NSString *requestBody = [NSString stringWithFormat:@"&vendorID=%@", [czzAppDelegate sharedAppDelegate].vendorID];
    [request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

#pragma mark - NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if (delegate) {
        [delegate notificationDownloaded:nil];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    receivedData = [NSMutableData new];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSMutableArray *notifications = [NSMutableArray new];
    NSError *error;
    SMXMLDocument *xmlDoc = [SMXMLDocument documentWithData:receivedData error:&error];
    for (SMXMLElement *element in xmlDoc.root.children) {
        if ([element.name isEqualToString:@"message"]) {
            czzNotification *notification = [[czzNotification alloc] initWithXMLElement:element];
            if (notification) {
                [notifications addObject:notification];
            }
        }
    }
    if (delegate) {
        [delegate notificationDownloaded:notifications];
    }
}
@end
