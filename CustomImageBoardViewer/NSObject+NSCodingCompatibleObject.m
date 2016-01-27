//
//  NSObject+NSCodingCompatibleObject.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/12/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "NSObject+NSCodingCompatibleObject.h"

@implementation NSObject (NSCodingCompatibleObject)

#pragma mark - NSCoding delegate
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    @try {
        NSDictionary *properties = [NSObject classPropsFor:self.class];
        for (PropertyAttribute *property in properties.allValues) {
            if (property.propertyAttributeType != PropertyAttributeTypeReadOnly) {
                id value = [aDecoder decodeObjectForKey:property.propertyName];
                [self setValue:value forKey:property.propertyName];
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    NSDictionary *properties = [NSObject classPropsFor:self.class];
    for (PropertyAttribute *property in properties.allValues) {
        [aCoder encodeObject:[self valueForKey:property.propertyName] forKey:property.propertyName];
    }
}

@end
