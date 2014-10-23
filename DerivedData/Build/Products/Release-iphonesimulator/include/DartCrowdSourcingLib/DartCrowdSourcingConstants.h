//
//  DartCrowdSourcingConstants.h
//  DartCrowdSourcingLib
//
//  Created by Craig on 24/06/2014.
//  Copyright (c) 2014 Optus. All rights reserved.
//

#import <Foundation/Foundation.h>

#define REFUSE_THRESHOLD 3 //how many times I should refuse permission before a permission grant

#define CROWD_SOURCING_LOG_EVENT @"Logger_Log"
#define CROWD_SOURCING_DEBUG_EVENT @"Logger_Debug"
#define CROWD_SOURCING_UPLOAD_EVENT @"Logger_Upload"

#define DART_UPLOAD_URL_PREFIX_PROD @"http://dart.optuszoo.com.au/dart/records/open/create/"
#define DART_UPLOAD_URL_PREFIX_DEBUG @"http://dart.optuszoo.com.au/dart/records/open/createcache/"

#define CROWD_SOURCING_LIB_API_KEY @"TESTDARTLIB"
#define CROWD_SOURCING_HOME_MCC_MNC @"50502"
#define CROWD_SOURCING_TESTER_ID @"dartIOSCrowdSourcingLib@optus.com.au"
#define CROWD_SOURCING_LIB_VERSION @"0.1"

#ifdef DEBUG
    #define CROWD_SOURCING_UPDATE_TIME_LONG 5 //default run time in second for a long update
    #define CROWD_SOURCING_UPDATE_TIME_SHORT 2 //for a short update
#else
    #define CROWD_SOURCING_UPDATE_TIME_LONG 15 //default run time in second for a long update
    #define CROWD_SOURCING_UPDATE_TIME_SHORT 5 //for a short update
#endif
#define CROWD_SOURCING_CONTROL_BACKGROUND_FETCH_INTERVAL //if I have control of background fetch interval

@interface DartCrowdSourcingConstants : NSObject
+(BOOL)isEnabled;
+(void)setEnabled:(BOOL)enable;
+(BOOL)isGPSEnabled;
+(void)setEnableGPS:(BOOL)enable;
+(BOOL)isBackgroundGPSEnabled;
+(void)setEnableBackgroundGPS:(BOOL)enable;
+(void)setEnableControlBackgroundFetchInterval:(BOOL)enable;
+(void)setMsisdn:(NSString*)msisdn;
+(NSString*)msisdn;
+(BOOL)isControlOfBackgroundFetchIntervalEnabled;
+(BOOL)requestToPerformGPSLongUpdate; //will return YES for the first time, then return a few NO for the following requests, then a YES
+(void)resetSettings;

+(DartCrowdSourcingConstants*)sharedInstance;
@end
