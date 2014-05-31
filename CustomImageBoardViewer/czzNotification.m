//
//  czzNotification.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotification.h"
#import "SMXMLDocument.h"

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
@synthesize replayToID;

-(id)initWithXMLData:(NSData *)xmlData {
    self = [super init];
    if (self) {
        [self assignPropertyWithXMLData:xmlData];
    }
    return self;
}

#pragma mark - assign properties with xml data
-(void)assignPropertyWithXMLData:(NSData*)xmlData {
    NSError *error;
    SMXMLDocument *xmlDocument = [SMXMLDocument documentWithData:xmlData error:&error];
    if (error) {
        NSLog(@"error: %@", error);
        return;
    }
    for (SMXMLElement *child in xmlDocument.root.children) {
        NSLog(@"%@, %@", child.name, child.value);
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
    [coder encodeObject:replayToID forKey:@"replayToID"];
}

-(id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        [decoder decodeObjectForKey:@"sender"];
        [decoder decodeObjectForKey:@"topic"];
        [decoder decodeObjectForKey:@"title"];
        [decoder decodeObjectForKey:@"description"];
        [decoder decodeObjectForKey:@"content"];
        [decoder decodeObjectForKey:@"date"];
        [decoder decodeIntegerForKey:@"emotion"];
        [decoder decodeObjectForKey:@"thImgSrc"];
        [decoder decodeObjectForKey:@"imgSrc"];
        [decoder decodeObjectForKey:@"link"];
        [decoder decodeIntegerForKey:@"priority"];
        [decoder decodeObjectForKey:@"notificationID"];
        [decoder decodeObjectForKey:@"replyToID"];
    }
    return self;
}
@end
