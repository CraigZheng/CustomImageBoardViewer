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
- (void)postSenderManager:(czzPostSenderManager *)manager startPostingForSender:(czzPostSender *)postSender;
- (void)postSenderManager:(czzPostSenderManager *)manager postingCompletedForSender:(czzPostSender *)postSender success:(BOOL)success message:(NSString *)message;
- (void)postSenderManager:(czzPostSenderManager *)manager severeWarningReceivedForPostSender:(czzPostSender*)postSender;
- (void)postSenderManager:(czzPostSenderManager *)manager postSender:(czzPostSender *)postSender progressUpdated:(CGFloat)percentage;
@end

@interface czzPostSenderManager : NSObject
@property (nonatomic, readonly) czzPostSender* lastPostSender;
@property (nonatomic, strong) czzPostSender *lastFailedPostSender;
@property (nonatomic, strong) czzPostSender *severeWarnedPostSender;
- (void)firePostSender:(czzPostSender *)postSender;
-(void)addDelegate:(id<czzPostSenderManagerDelegate>)delegate;
-(void)removeDelegate:(id<czzPostSenderManagerDelegate>)delegate;
-(BOOL)hasDelegate:(id<czzPostSenderManagerDelegate>)delegate;

+ (instancetype)sharedManager;
@end
