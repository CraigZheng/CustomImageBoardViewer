//
//  WifiInfo.h
//  DartPassiveCollectorLib
//
//  Created by Craig on 29/05/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WifiAccessPoint.h"
#import "WifiState.h"

@interface WifiInfo : NSObject
@property (nonatomic) NSString *SSID;
@property (nonatomic) NSString *BSSID;

-(BOOL)isConnected;
-(WifiAccessPoint*)getWifiAccessPoint;
-(WifiState*)getWifiState;
@end
