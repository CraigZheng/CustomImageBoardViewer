//
//  czzWKThread.m
//  CustomImageBoardViewer
//
//  Created by Craig on 18/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzWKThread.h"
#import "czzThread.h"

@implementation czzWKThread

#pragma mark - Getters

- (czzThread *)fatThread {
    czzThread *thread = [czzThread new];
    thread.ID = self.ID;
    thread.title = self.title;
    thread.name = self.name;
    thread.content = [[NSAttributedString alloc] initWithString:self.content];
    thread.postDateTime = self.postDate;
    thread.thImgSrc = self.thumbnailFile;
    thread.imgSrc = self.imageFile;
    
    return thread;
}

#pragma mark - NSSecureCoding


-(instancetype)initWithDictionary:(NSDictionary *)dict {
    if ([dict isKindOfClass:[NSDictionary class]] && dict.count) {
        self = [self init];
        self.ID = [[dict objectForKey:@"ID"] integerValue];
        self.name = [dict objectForKey:@"name"];
        self.title = [dict objectForKey:@"title"];
        self.content = [dict objectForKey:@"content"];
        self.thumbnailFile = [dict objectForKey:@"thumbnailFile"];
        self.imageFile = [dict objectForKey:@"imageFile"];
        self.postDate = [dict objectForKey:@"postDate"];
    }
    
    return self;
}

-(NSDictionary *)encodeToDictionary {
    NSMutableDictionary *wkDictionary = [NSMutableDictionary new];
    [wkDictionary setObject:@(self.ID) forKey:@"ID"];
    [wkDictionary setObject:self.name forKey:@"name"];
    [wkDictionary setObject:self.title forKey:@"title"];
    [wkDictionary setObject:self.content forKey:@"content"];
    [wkDictionary setObject:self.thumbnailFile forKey:@"thumbnailFile"];
    [wkDictionary setObject:self.imageFile forKey:@"imageFile"];
    [wkDictionary setObject:self.postDate forKey:@"postDate"];
    
    return wkDictionary;
}

#pragma mark - Description
-(NSString *)description {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"h:m:s";
    return [NSString stringWithFormat:@"%@ %@: %@", self.name, [dateFormatter stringFromDate:self.postDate], self.content];
}

@end
