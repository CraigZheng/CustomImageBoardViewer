//
//  czzXMLDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzXMLDownloader.h"

@interface czzXMLDownloader()
@property NSURLConnection *urlConn;
@property NSMutableData *receivedXMLData;
@end

@implementation czzXMLDownloader
@synthesize urlConn;
@synthesize targetURL;
@synthesize receivedXMLData;

-(id)initWithTargetURL:(NSURL *)url delegate:(id<czzXMLDownloaderDelegate>)delegate startNow:(BOOL)now{
    self = [super init];
    if (self){
        targetURL = url;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:targetURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
        [request setHTTPShouldHandleCookies:YES];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];

        urlConn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:now];
        self.delegate = delegate;
    }
    return self;
}

-(void)start{
    [urlConn start];
}

-(void)stop{
    [urlConn cancel];
}

-(void)setTargetURL:(NSURL *)url{
    targetURL = url;
    urlConn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
}

#pragma NSURLConnectionDelegate
-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response{
    self.receivedXMLData = [NSMutableData new];

    NSDictionary *dict = [(NSHTTPURLResponse*)response allHeaderFields];
    for (NSString *header in dict) {
        //NSLog(@"%@:%@", header, [dict objectForKey:header]);
    }
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)data{
    [self.receivedXMLData appendData:data];
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
        [self.delegate downloadOf:connection.currentRequest.URL successed:NO result:nil];
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection*)connection{
    if ([self.delegate respondsToSelector:@selector(downloadOf:successed:result:)]){
        [self.delegate downloadOf:connection.currentRequest.URL successed:YES result:self.receivedXMLData];
    }

}
@end
