//
//  DeviceHardware.m
//  DartCrowdSourcingLib
//
//  Created by Craig on 2/12/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import "DeviceHardware.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation DeviceHardware
+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}
+ (NSString *) platformString{
    NSString *platform = [self platform];
    return platform;
}

+(NSString *)platformName {
    NSString *platform = [self platformString];
    //copied from http://www.everyi.com/by-identifier/ipod-iphone-ipad-specs-by-model-identifier.html
    if ([platform isEqualToString:@"iPhone7,2"])
        return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])
        return @"iPhone 6 Plus";
    
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5S";
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5S";
    
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 1G";
    
    if ([platform isEqualToString:@"iPad4,1"])
        return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])
        return @"iPad Air (3G)";
    if ([platform isEqualToString:@"iPad4,3"])
        return @"iPad Air (4G)";
    if ([platform isEqualToString:@"iPad4,4"])
        return @"iPad Mini 2 (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])
        return @"iPad Mini 2 (Celluar)";
    if ([platform isEqualToString:@"iPad4,6"])
        return @"iPad Mini 2";
    
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3 Wi-Fi";
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3 GSM";
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3 CDMA";
    
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4 AT";
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4 VS";
    
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2G (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2G (CDMA)";
    
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G WiFi";
    if ([platform isEqualToString:@"iPad1,2"])   return @"iPad 1G 3G";
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G WiFi";
    
    if ([platform isEqualToString:@"iPhone2,5"]) return @"iPad Mini";
    if ([platform isEqualToString:@"iPhone2,6"]) return @"iPad Mini AT";
    if ([platform isEqualToString:@"iPhone2,7"]) return @"iPad Mini VS";
    
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPod touch 4G";
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPod touch 3G";
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPod touch 2G";
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPod touch 1G";
    
    if ([platform isEqualToString:@"AppleTV2,1"]) return @"Apple TV 2G";
    if ([platform isEqualToString:@"i386"])  return @"iPhone Simulator";
    return platform;

}
+ (BOOL)iPhone4{
    return [[self platformString] isEqualToString:@"iPhone 4"];
}
+ (BOOL)simulator{
    return [[self platformString] isEqualToString:@"iPhone Simulator"];
}
@end