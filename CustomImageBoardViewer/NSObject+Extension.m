//
//  NSObject+Extension.m
//  CustomImageBoardViewer
//
//  Created by Craig on 9/03/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "NSObject+Extension.h"

@implementation NSObject (Extension)

-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name {
    if ([[dict valueForKey:name] isEqual:[NSNull null]]) {
        return nil;
    }
    id value = [dict valueForKey:name];
    return value;
}

@end
