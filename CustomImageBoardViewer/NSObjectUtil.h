//
//  NSObjectUtil.h
//  roomfindr
//
//  Created by Craig Zheng on 4/09/2014.
//  Copyright (c) 2014 cz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObjectUtil : NSObject

+ (NSDictionary *)classPropsFor:(Class)klass;
@end
