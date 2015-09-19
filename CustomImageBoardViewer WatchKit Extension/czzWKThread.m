//
//  czzWKThread.m
//  CustomImageBoardViewer
//
//  Created by Craig on 18/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzWKThread.h"

@implementation czzWKThread

-(NSDictionary *)encodeToDictionary {
    NSMutableDictionary *wkDictionary = [NSMutableDictionary new];
    
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
