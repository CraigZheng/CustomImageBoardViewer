//
//  DartCrowdSourcingLib.h
//  DartCrowdSourcingLib
//
//  Created by Craig on 13/06/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#import "DartCrowdSourcingConstants.h"

@interface DartCrowdSourcingLib : NSObject <CLLocationManagerDelegate>
//production properties
@property NSString *apiKey;
@property NSString *version;
@property NSString *uploadURL;
@property NSString *homeMccMnc;
@property NSString *msisdn;
@property (nonatomic) NSString *logFile;
@property (nonatomic) NSString *debugLog;

//debug properties
@property NSString *testerId;
@property BOOL isSlave;
@property NSString *masterAppPackage;
@property NSString *masterAppVersion;
@property BOOL debug;
@property NSString *uploadURLDebug;


/**
 Production constructor, accepts api key, version, home mcc and mnc, upload url, no tester id is given
 */
+(id)initWithApiKey:(NSString*)apiKey version:(NSString*)version homeMccMnc:(NSString*)mccmnc uploadURL:(NSString*)uploadURL;
/**
 Default constructor, all parameters accept nil, in such case, default values will be used
 */
+(id)initWithApiKey:(NSString*)apiKey version:(NSString*)version homeMccMnc:(NSString*)mccmnc testerID:(NSString* )testerID uploadURL:(NSString*)uploadURL;


+(void)enableCollection;
+(void)disableCollection;
+(BOOL)isEnabled;
+(void)manualUpload;
+(void)setMsisdn:(NSString*)msisdn;

+(void)reportHTTPEvent:(BOOL)wasSuccessful :(NSInteger)bytes :(NSInteger)timeInMS :(NSInteger)numberOfThreads :(CGFloat)speedKbps :(NSString*)errors;
+(void)reportMiscInfo:(NSString*)miscInfo;
+(void)uploadLogsIfNeeded:(BOOL)forceUpload;

+(DartCrowdSourcingLib*)sharedInstance;
+(void)performBackgroundLoggingWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler andResult:(UIBackgroundFetchResult)result;
+(void)endBackgroundLogging;
@end
