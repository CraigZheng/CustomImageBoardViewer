//
//  czzFeedback.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define feedback_host @"http://civ.atwebpages.com/php/feedback.php"

#import <Foundation/Foundation.h>

enum {
    happy = 0,
    very_happy = 1,
    sad = 2,
    angry = 3,
    other = 4
};
typedef NSUInteger emotions;

@interface czzFeedback : NSObject

@property (nonatomic) NSString *access_token;
@property (nonatomic) NSString *vendorID;
@property NSString *topic;
@property NSString *title;
@property (nonatomic) NSDate *time;
@property NSString *name;
@property NSString *content;
@property NSString *emotion;

-(BOOL)sendFeedback;
@end
