//
//  czzNotification.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotification.h"

@interface czzNotification()<NSCoding>
@end

@implementation czzNotification
@synthesize sender;
@synthesize topic;
@synthesize title;
@synthesize description;
@synthesize content;
@synthesize date;
@synthesize emotion;
@synthesize thImgSrc;
@synthesize imgSrc;
@synthesize link;
@synthesize priority;
@synthesize notificationID;
@synthesize replyToID;
@synthesize read;

-(id)initWithXMLElement:(SMXMLElement *)xmlElement {
    self = [super init];
    if (self) {
        [self assignPropertyWithXMLData:xmlElement];
        if (!self.notificationID || !self.title) {
            return nil;
        }
    }
    return self;
}

#pragma mark - assign properties with xml data
-(void)assignPropertyWithXMLData:(SMXMLElement*)xmlElement {
    
    for (SMXMLElement *child in xmlElement.children) {
        NSLog(@"%@, %@", child.name, child.value);
        if ([child.name isEqualToString:@"sender"]) {
            self.sender = child.value;
        } else if ([child.name isEqualToString:@"topic"]){
            self.topic = child.value;
        }else if ([child.name isEqualToString:@"title"]){
            self.title = child.value;
        }
        else if ([child.name isEqualToString:@"description"]){
            self.description = child.value;
        }
        else if ([child.name isEqualToString:@"content"]){
            self.content = child.value;
        }
        else if ([child.name isEqualToString:@"date"]){
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"yyyy-MMM-dd hh:mm:ss";
            self.date = [dateFormatter dateFromString:child.value];
            
        }
        else if ([child.name isEqualToString:@"emotion"]){
            self.emotion = [child.value integerValue];
        }
        else if ([child.name isEqualToString:@"thImgSrc"]){
            self.thImgSrc = child.value;
        }
        else if ([child.name isEqualToString:@"imgSrc"]){
            self.imgSrc = child.value;
        }
        else if ([child.name isEqualToString:@"link"]){
            self.link = child.value;
        }
        else if ([child.name isEqualToString:@"priority"]){
            self.priority = [child.value integerValue];
        }
        else if ([child.name isEqualToString:@"notificationID"]){
            self.notificationID = child.value;
        }
        else if ([child.name isEqualToString:@"replyToID"]){
            self.replyToID = child.value;
        }
    }
    
}

#pragma mark - encoding/decoding

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:sender forKey:@"sender"];
    [coder encodeObject:topic forKey:@"topic"];
    [coder encodeObject:title forKey:@"title"];
    [coder encodeObject:description forKey:@"description"];
    [coder encodeObject:content forKey:@"content"];
    [coder encodeObject:date forKey:@"date"];
    [coder encodeInteger:emotion forKey:@"emotion"];
    [coder encodeObject:thImgSrc forKey:@"thImgSrc"];
    [coder encodeObject:imgSrc forKey:@"imgSrc"];
    [coder encodeObject:link forKey:@"link"];
    [coder encodeInteger:priority forKey:@"priority"];
    [coder encodeObject:notificationID forKey:@"notificationID"];
    [coder encodeObject:replyToID forKey:@"replyToID"];
    [coder encodeBool:read forKey:@"read"];
}

-(id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.sender = [decoder decodeObjectForKey:@"sender"];
        self.topic = [decoder decodeObjectForKey:@"topic"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.description = [decoder decodeObjectForKey:@"description"];
        self.content = [decoder decodeObjectForKey:@"content"];
        self.date = [decoder decodeObjectForKey:@"date"];
        self.emotion = [decoder decodeIntegerForKey:@"emotion"];
        self.thImgSrc = [decoder decodeObjectForKey:@"thImgSrc"];
        self.imgSrc = [decoder decodeObjectForKey:@"imgSrc"];
        self.link = [decoder decodeObjectForKey:@"link"];
        self.priority = [decoder decodeIntegerForKey:@"priority"];
        self.notificationID = [decoder decodeObjectForKey:@"notificationID"];
        self.replyToID = [decoder decodeObjectForKey:@"replyToID"];
        self.read = [decoder decodeBoolForKey:@"read"];
    }
    return self;
}
@end
