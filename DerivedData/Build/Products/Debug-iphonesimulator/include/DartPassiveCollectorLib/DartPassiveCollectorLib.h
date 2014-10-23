//
//  DartPassiveCollectorLib.h
//  DartPassiveCollectorLib
//
//  Created by Craig on 29/05/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "CellInfo.h"
#import "BatteryInfo.h"
#import "LocationInfo.h"
#import "WifiInfo.h"
#import "IpAddressInfo.h"

#import "CollectorConfig.h"

#import "HttpEventType.h"

@class Logger;
@protocol DartPassiveCollectorLibProtocol <NSObject>
-(void)locationInfoUpdated:(CLLocation*)newLocation;
@end

@interface DartPassiveCollectorLib : NSObject
@property (nonatomic) NSString *apiKey;
@property (nonatomic) NSString *msisdn;
@property NSString *testerId;
@property NSString *version;
@property NSString *uploadURL;
@property BOOL isLogging;
@property id<DartPassiveCollectorLibProtocol> delegate;
@property Logger *logger;
@property NSInteger logFileUploadThreshold;

-(void)startRecording;
-(void)endRecording;
-(void)startUpdateLocation; //request GPS update
-(void)stopUpdateLocation; //stop GPS updating
-(void)uploadLogsIfNeeded:(BOOL)forceUpload;

//call to print a line to logger
-(void)printCellLine; //print with private API when in DEBUG mode, otherwise print without private API
-(void)printSimpleCellLine; //without private API
-(void)printCompleteCellLine; //with private API
-(void)printBatteryLine;
-(void)printLocationLine;
-(void)printHttpEventLine:(HttpEventType*)httpEventType :(BOOL)wasSuccessful :(NSInteger)bytes :(NSInteger)timeinMs :(NSInteger)numThreads :(CGFloat)speedKbps :(NSString*)errors :(BOOL)forceLog; //the forceLog parameter does nothing ATM
-(void)printWifiLine;
-(void)printDebugLine:(NSString*)info;
-(void)printMiscInfoLine:(NSString*)info;

-(NSString*)logFileContent;
-(NSString*)debugLogContent;
@end
