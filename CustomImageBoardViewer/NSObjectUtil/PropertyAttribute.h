//
//  PropertyAttribute.h
//  DartCrowdSourcingLib
//
//  Created by Craig on 8/09/2015.
//  Copyright (c) 2015 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>

// There could be more, but to me they are not useful.
typedef NS_ENUM(NSInteger, PropertyAttributeType) {
    PropertyAttributeTypeReadOnly = 1, //R
    PropertyAttributeTypeReadWrite = 0
};

@interface PropertyAttribute : NSObject
@property (nonatomic, strong) NSString *propertyName;
@property (nonatomic, strong) NSString *propertyType;
@property (nonatomic, assign) PropertyAttributeType propertyAttributeType;
@end
