//
//  czzFeedback.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define feedback_host @"php/feedback.php?"

#import <Foundation/Foundation.h>
#import "czzNotification.h"

@interface czzFeedback : NSObject

@property (nonatomic) NSString *access_token;
@property NSString *topic;
@property NSString *title;
@property (nonatomic) NSString *time;
@property NSString *name;
@property NSString *content; //required
@property EMOTIONS emotion;

-(BOOL)sendFeedback:(czzNotification*)notification;
@end
