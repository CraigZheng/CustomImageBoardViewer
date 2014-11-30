//
//  czzJSONProcessor.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 6/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzThread;
@class czzJSONProcessor;
@protocol czzJSONProcessorDelegate<NSObject>
@optional
-(void)threadListProcessed:(czzJSONProcessor*)processor :(NSArray*)newThread :(BOOL)success;
-(void)subThreadProcessedForThread:(czzJSONProcessor*)processor :(czzThread*)parentThread :(NSArray*)newThread :(BOOL) success;

-(void)threadListProcessed:(NSArray*)newThread :(BOOL)success;
-(void)subThreadProcessedForThread:(czzThread*)parentThread :(NSArray*)newThread :(BOOL) success;
@end

@interface czzJSONProcessor : NSObject
-(void)processThreadListFromData:(NSData*)jsonData;
-(void)processSubThreadFromData:(NSData*)jsonData;

@property id<czzJSONProcessorDelegate> delegate;
@end

