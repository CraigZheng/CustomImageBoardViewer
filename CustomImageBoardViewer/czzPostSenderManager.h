//
//  czzPostSenderManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 22/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PostSenderManager [czzPostSenderManager sharedManager]

@class czzPostSender, czzPostSenderManager;

@protocol czzPostSenderManagerDelegate <NSObject>
@optional
- (void)postSenderManager:(czzPostSenderManager *)manager postingCompletedForSender:(czzPostSender *)postSender success:(BOOL)success message:(NSString *)message;
@end

@interface czzPostSenderManager : NSObject

- (void)firePostSender:(czzPostSender *)postSender;
-(void)addDelegate:(id<czzPostSenderManagerDelegate>)delegate;
-(void)removeDelegate:(id<czzPostSenderManagerDelegate>)delegate;
-(BOOL)hasDelegate:(id<czzPostSenderManagerDelegate>)delegate;

+ (instancetype)sharedManager;
@end
