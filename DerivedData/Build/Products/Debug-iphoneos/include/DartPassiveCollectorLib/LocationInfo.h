//
//  LocationInfo.h
//  DartPassiveCollectorLib
//
//  Created by Craig on 29/05/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol LocationInfoProtocol <NSObject>
-(void)locationUpdated:(CLLocation*)newLocation;
@end

@interface LocationInfo : NSObject
@property NSTimeInterval timeOutInterval;
@property CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;
@property id<LocationInfoProtocol> delegate;

-(id)initWithDelegate:(id<LocationInfoProtocol>)del;
-(void)startUpdatingLocationInfo;
-(void)stopUpdatingLocationInfo;
@end
