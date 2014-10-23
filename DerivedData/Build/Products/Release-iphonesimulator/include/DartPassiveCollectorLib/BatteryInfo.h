//
//  BatteryInfo.h
//  DartPassiveCollectorLib
//
//  Created by Craig on 29/05/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BatteryInfo : NSObject
@property (nonatomic) NSInteger batteryLevel;
@property (nonatomic) UIDeviceBatteryState batteryState;
@property (nonatomic) BOOL isCharging;
-(id)init;
@end
