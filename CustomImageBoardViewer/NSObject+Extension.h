//
//  NSObject+Extension.h
//  CustomImageBoardViewer
//
//  Created by Craig on 9/03/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface NSObject (Extension)
-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name;
- (UIColor *) colorForHex:(NSString *)hexColor;

+ (NSDictionary *)classPropsFor:(Class)klass;

@end
