//
//  NSObject+Util.h
//  DartCrowdSourcingLib
//
//  Created by Craig on 8/09/2015.
//  Copyright (c) 2015 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PropertyAttribute.h"
#import <objc/runtime.h>

@interface NSObject (Util)

+ (NSDictionary *)classPropsFor:(Class)klass;
@end
