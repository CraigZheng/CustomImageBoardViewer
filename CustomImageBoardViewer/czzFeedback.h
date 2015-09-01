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
@property (strong, nonatomic) NSString *topic;
@property (strong, nonatomic) NSString *title;
@property (nonatomic) NSString *time;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *content; //required
@property EMOTIONS emotion;

-(BOOL)sendFeedback:(czzNotification*)notification;
@end
