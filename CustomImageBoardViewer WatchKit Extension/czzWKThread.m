//
//  czzWKThread.m
//  CustomImageBoardViewer
//
//  Created by Craig on 18/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzWKThread.h"

@implementation czzWKThread

#pragma mark - NSSecureCoding

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.title = [aDecoder decodeObjectForKey:@"title"];
    self.content = [aDecoder decodeObjectForKey:@"content"];
    self.thumbnailFile = [aDecoder decodeObjectForKey:@"thumbnailFile"];
    self.imageFile = [aDecoder decodeObjectForKey:@"imageFile"];
    self.postDate = [aDecoder decodeObjectForKey:@"postDate"];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.content forKey:@"content"];
    [aCoder encodeObject:self.thumbnailFile forKey:@"thumbnailFile"];
    [aCoder encodeObject:self.imageFile forKey:@"imageFile"];
    [aCoder encodeObject:self.postDate forKey:@"postDate"];
}

+(BOOL)supportsSecureCoding{
    return YES;
}

#pragma mark - Description
-(NSString *)description {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"h:m:s";
    return [NSString stringWithFormat:@"%@ %@: %@", self.name, [dateFormatter stringFromDate:self.postDate], self.content];
}

@end
