//
//  Logger.h
//  DartPassiveCollectorLib
//
//  Created by Craig on 29/05/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#define UPLOAD_FLAG_EMAIL_ME_MY_RESULTS 1

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "WifiInfo.h"
#import "CollectorConfig.h"

#import "V2Encoder.h"
#import "LocationProviderType.h"
#import "RatType.h"
#import "NetworkType.h"
#import "WifiState.h"
#import "HRV2Encoder.h"
#import "MRV2Encoder.h"
#import "HttpEventType.h"
#import "FileStore.h"
#import "IpAddressInfo.h"
#import "DartPayloadCodec.h"
#import "ObjCJsonSerialiser.h"
#import "LogFormatVersion.h"

@protocol LoggerDelegate <NSObject>

@end

@interface Logger : NSObject
@property (nonatomic) NSString *apiKey;
@property NSString *imei;
@property NSString *imsi;
@property NSString *msisdn;
@property NSString *phoneManufacturer;
@property NSString *phoneModel;
@property NSString *phoneOSVer;

-(id)initWithApiKey:(NSString*)apiKey saveOldLogFiles:(BOOL)saveOLF debug:(BOOL)d logFileDeleteThreshold:(int)lfdt;

-(void)flush;
-(void)endRecording;
-(BOOL)hasNewData;
-(NSString*)getUploadPayload:(NSString*)testerId version:(NSString*)version flag:(const int)flag;
-(void)disableLogging;
-(void)enableLogging;
-(BOOL)isDisabled;
-(void)deleteAll;

-(NSString*)getImsi;
-(NSString*)getImei;
-(NSString*)getApiKey;
-(NSString*)getLog;
-(NSString*)getDebugLog;
-(long)getLogSize;
-(NSString*)getPhoneManufacturer;
-(NSArray*)getAllLogAndSavedFiles;
-(NSString*)getFileContents:(NSString*)file;


-(void)printActivityLine:(NSString*)activity heading:(NSString*)heading summary:(NSString*)summary key:(NSString*)key value:(NSString*)value;
-(void)printBatteryLine:(NSInteger)level level:(BOOL)charging; //on iOS, you can not detect if the screen is on
-(void)printDebugLine:(NSString*)freeText;
-(void)printEndRun;
-(void)printHttpEventV4Line:(HttpEventType*)httpEventType wasSuccessful:(BOOL)wasSuccessful bytes:(NSInteger)bytes timeInMs:(NSInteger)timeInMs numThreads:(NSInteger)numThreads speedKBps:(CGFloat)speedKBps errors:(NSString*)errors forceLog:(BOOL)forceLog;
-(void)printLocationLine:(CGFloat)lat longitute:(CGFloat)lon accuracy:(NSInteger)accuracy altitute:(NSInteger)altitute speed:(NSInteger)speed course:(CGFloat)course locationProviderType:(LocationProviderType*)locationProviderType;
-(void)printMiscInfoLine:(NSString*)info;
-(void)printRadioLine:(RatType*)ratType mccmnc:(NSInteger)mccmnc cid:(NSInteger)cid lac:(NSInteger)lac sigStrength:(NSInteger)sigStrength bars:(NSInteger)bars rsrq:(NSInteger)rsrq snr:(NSInteger)snr uarfcn:(NSInteger)uarfcn networkType:(NetworkType*)networkType;

-(void)printRadioStateLine:(BOOL)isUp ipAddress:(NSString*)ipAddress imsi:(NSString*)imsi;
-(void)printStartRun;
-(void)printWifiLine:(WifiState*)wifiState connectedWifiAP:(WifiAccessPoint*)wifiAccesspoitn totalWifiAps:(short)totalWifiAps scanWifiAPs:(NSArray*)scanWiFiAPs;

@end
