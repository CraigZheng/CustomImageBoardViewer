//
//  DartURLConnection.h
//  DartCrowdSourcingLib
//
//  Created by Craig on 18/06/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

/*
 this class offers all the functions of the NSURLConnection class, plus logging the speed of the connection and more
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DartCrowdSourcingLib.h"

@class DartURLConnection;
@protocol DartURLConnectionDelegate <NSObject>
@optional
-(void)connection:(DartURLConnection *)connection didReceiveData:(NSData *)data;
-(void)connection:(DartURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void)connection:(DartURLConnection *)connection didFailWithError:(NSError *)error;
-(void)connectionDidFinishLoading:(DartURLConnection *)connection;

@end

@interface DartURLConnection : NSObject
@property DartCrowdSourcingLib *crowdSourcingLib;
@property id<DartURLConnectionDelegate> delegate;
@property NSInteger numberOfThreads;

-(id)initWithRequest:(NSURLRequest*)request delegate:(id<DartURLConnectionDelegate>)_delegate startImmediately:(BOOL)startImmediately;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id < DartURLConnectionDelegate >)_delegate;
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)setDelegateQueue:(NSOperationQueue *)queue;

-(void)start;
-(void)cancel;
@end
