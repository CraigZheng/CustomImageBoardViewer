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
    sad = -1,
    neutral = 0,
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
@property (nonatomic, strong) NSString *sender;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSString *title;//required
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *date; //date format: yyyy-MMM-dd hh:mm:ss
@property EMOTIONS emotion;
@property (nonatomic, strong) NSString *thImgSrc;
@property (nonatomic, strong) NSString *imgSrc;
@property (nonatomic, strong) NSString *link;
@property PRIORITY priority;
@property (nonatomic, strong) NSString *notificationID; //required
@property (nonatomic, strong) NSString *replyToID;
@property NSInteger shouldDisplayXTimes; //default is 1;
//local fields
@property BOOL hasDisplayed;
@property NSInteger timeBeenDisplayed;
@property BOOL hasOpened;
-(id)initWithXMLElement:(SMXMLElement*)xmlElement;
@end
