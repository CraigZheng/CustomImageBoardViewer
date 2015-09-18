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
    self.name = [aDecoder decodeObjectOfClass:[czzWKThread class] forKey:@"name"];
    self.title = [aDecoder decodeObjectOfClass:[czzWKThread class] forKey:@"title"];
    self.content = [aDecoder decodeObjectOfClass:[czzWKThread class] forKey:@"content"];
    self.thumbnailFile = [aDecoder decodeObjectOfClass:[czzWKThread class] forKey:@"thumbnailFile"];
    self.imageFile = [aDecoder decodeObjectOfClass:[czzWKThread class] forKey:@"imageFile"];
    self.postDate = [aDecoder decodeObjectOfClass:[czzWKThread class] forKey:@"postDate"];
    
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

-(instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    self.name = [dict objectForKey:@"name"];
    self.title = [dict objectForKey:@"title"];
    self.content = [dict objectForKey:@"content"];
    self.thumbnailFile = [dict objectForKey:@"thumbnailFile"];
    self.imageFile = [dict objectForKey:@"imageFile"];
    self.postDate = [dict objectForKey:@"postDate"];
    
    return self;
}

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
