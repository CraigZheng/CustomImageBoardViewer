//
//  czzBlacklistSender.h
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzBlacklistEntity.h"

@protocol czzBlacklistSenderDelegate <NSObject>
@optional
-(void)statusReceived:(BOOL)status message:(NSString*)message;
@end

@interface czzBlacklistSender : NSObject
@property czzBlacklistEntity *blacklistEntity;
@property NSString *targetURLString;
-(void)sendBlacklistUpdate;

@property id<czzBlacklistSenderDelegate> delegate;
@end
