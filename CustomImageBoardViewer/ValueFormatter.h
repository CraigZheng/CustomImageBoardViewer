//
//  ValueFormatter.h
//  SignalAnalyzer
//
//  Created by Craig on 20/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ValueFormatter : NSObject

+(NSString*)convertMilliSeconds:(CGFloat)ms;
+(NSString*)convertBPS:(CGFloat)bitsPerSecond;
+(NSString*)convertByte:(NSUInteger)bytes;
@end
