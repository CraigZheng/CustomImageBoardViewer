//
//  NSDictionary+Util.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "NSDictionary+Util.h"

@implementation NSDictionary (Util)

-(id)jsonValueWithKey:(NSString *)key {
    id value = [self objectForKey:key];
    if ([value isEqual:[NSNull null]]) {
        value = nil;
    }
    return value;
}
@end
