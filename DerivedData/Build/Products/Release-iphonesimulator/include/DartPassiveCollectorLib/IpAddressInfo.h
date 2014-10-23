//
//  IpAddress.h
//  DartPassiveCollectorLib
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IpAddressInfo : NSObject
@property (nonatomic) NSString *ipAddress;

+(NSString*)getIPAddress:(BOOL)preferIPv4;
+(int*)getIPAddress;
+(int*)getIPAddressIntArrayFromString:(NSString*)ipString;
@end
