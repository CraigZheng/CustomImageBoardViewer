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

@interface czzNotificationDownloader()<czzURLDownloaderProtocol>
@property NSMutableData *receivedData;

@end

@implementation czzNotificationDownloader
@synthesize notificationFile;
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
    //make a post request to the server with vendorID
    NSString *targetURLString = [AppDelegate.myhost stringByAppendingPathComponent:@"php"];
    targetURLString = [targetURLString stringByAppendingPathComponent:notificationFile];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:targetURLString]];
    [request setHTTPMethod:@"POST"];
    
    NSMutableData *requestData = [NSMutableData new];
#ifdef DEBUG
    vendorID = @"DEBUG";
#endif
    [requestData appendData:[[NSString stringWithFormat:@"&vendorID=%@", vendorID] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)requestData.length] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:requestData];
    
    self.urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLString] delegate:self startNow:YES];
}

#pragma mark - czzURLDownloaderProtocol
-(void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    NSMutableArray *notifications;
    if (successed) {
        receivedData = [NSMutableData dataWithData:downloadedData];
        NSError *error;
        SMXMLDocument *xmlDoc = [SMXMLDocument documentWithData:receivedData error:&error];
        notifications = [NSMutableArray new];
        for (SMXMLElement *element in xmlDoc.root.children) {
            if ([element.name isEqualToString:@"message"]) {
                czzNotification *notification = [[czzNotification alloc] initWithXMLElement:element];
                if (notification) {
                    [notifications addObject:notification];
                }
            }
        }
    }
    if (delegate) {
        [delegate notificationDownloaded:notifications];
    }
}

@end
