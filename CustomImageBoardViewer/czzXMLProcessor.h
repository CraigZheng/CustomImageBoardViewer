//
//  czzXMLProcessor.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/03/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol czzXMLProcessorDelegate <NSObject>
@optional
-(void)threadListProcessed:(NSArray*)newThread :(BOOL)success;
-(void)subThreadProcessed:(NSArray*)newThread :(BOOL) success;
-(void)messageProcessed:(NSString*)title :(NSString*)message :(NSInteger)howLong;
@end

@interface czzXMLProcessor : NSObject
-(void)processThreadListFromData:(NSData*)xmlData;
-(void)processSubThreadFromData:(NSData*)xmlData;

@property (weak, nonatomic) id<czzXMLProcessorDelegate> delegate;
@end
