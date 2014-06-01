//
//  czzNotification.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMXMLDocument.h"

enum {
    happy = 0,
    very_happy = 1,
    sad = 2,
    angry = 3,
    other = 4
};
typedef NSUInteger EMOTIONS;

enum {
    low = 0,
    medium = 1,
    high = 2,
    very_high = 3,
    sky_high = 4
};
typedef NSUInteger PRIORITY;

@interface czzNotification : NSObject
@property NSString *sender;
@property NSString *topic;
@property NSString *title;
@property NSString *description;
@property NSString *content; //required
@property NSDate *date; //date format: yyyy-MMM-dd hh:mm:ss
@property EMOTIONS emotion;
@property NSString *thImgSrc;
@property NSString *imgSrc;
@property NSString *link;
@property PRIORITY priority;
@property NSString *notificationID; //required
@property NSString *replyToID;

-(id)initWithXMLElement:(SMXMLElement*)xmlElement;
@end
