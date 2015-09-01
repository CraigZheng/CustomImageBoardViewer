//
//  DeviceHardware.h
//  DartCrowdSourcingLib
//
//  Created by Craig on 2/12/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

//copied from https://github.com/QuickBlox/SuperSample-ios/blob/master/Classes/Helpers/DeviceHardware/DeviceHardware.m

#import <Foundation/Foundation.h>

@interface DeviceHardware : NSObject

+ (NSString *) platform;
+ (NSString *) platformString;
+(NSString*)platformName;
+ (BOOL)iPhone4;
+ (BOOL)simulator;

@end
