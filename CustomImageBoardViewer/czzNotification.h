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
    sad = 0,
    happy = 1,
    very_happy = 2,
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
@property NSString *title;//required
@property NSString *description;
@property NSString *content;
@property NSDate *date; //date format: yyyy-MMM-dd hh:mm:ss
@property EMOTIONS emotion;
@property NSString *thImgSrc;
@property NSString *imgSrc;
@property NSString *link;
@property PRIORITY priority;
@property NSString *notificationID; //required
@property NSString *replyToID;
@property NSInteger shouldDisplayXTimes; //default is 1;
//local fields
@property BOOL hasDisplayed;
@property NSInteger timeBeenDisplayed;
@property BOOL hasOpened;
-(id)initWithXMLElement:(SMXMLElement*)xmlElement;
@end
