//
//  CellInfo.h
//  CTCollector
//
//  Created by Craig on 20/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define CONNECTION_2G @"2G"
#define CONNECTION_3G @"3G"
#define CONNECTION_4G @"4G"
#define CONNECTION_UNKNOWN @"Unknown connection"
#define CONNECTION_NO_CONNECTION @"No connection"
#define CONNECTION_WIFI @"WiFi"

#define CTRadioAccessTechnologyLTE @"CTRadioAccessTechnologyLTE"
#define CTRadioAccessTechnologyWCDMA @"CTRadioAccessTechnologyWCDMA"
#define CTRadioAccessTechnologyHSUPA @"CTRadioAccessTechnologyHSUPA"
#define CTRadioAccessTechnologyHSDPA @"CTRadioAccessTechnologyHSDPA"
#define CTRadioAccessTechnologyCDMA1x @"CTRadioAccessTechnologyCDMA1x"
#define CTRadioAccessTechnologyCDMAEVDORev0 @"CTRadioAccessTechnologyCDMAEVDORev0"
#define CTRadioAccessTechnologyCDMAEVDORevA @"CTRadioAccessTechnologyCDMAEVDORevA"
#define CTRadioAccessTechnologyCDMAEVDORevB @"CTRadioAccessTechnologyCDMAEVDORevB"
#define CTRadioAccessTechnologyEdge @"CTRadioAccessTechnologyEdge"
#define CTRadioAccessTechnologyGPRS @"CTRadioAccessTechnologyGPRS"

#import <Foundation/Foundation.h>

#import "NetworkType.h"
#import "RatType.h"

@interface CellInfo : NSObject
//public as iOS 7
@property (nonatomic) NSString *networkOperator;
@property (nonatomic) NSString *MCC;
@property (nonatomic) NSString *MNC;
@property (nonatomic) NSString *RAT;
@property (nonatomic) NSInteger MCCMNC;
//private
@property NSInteger CID;
@property NSInteger LAC;
@property NSInteger ECN0;
@property NSInteger RSCP;
@property NSInteger BARS;
@property NSInteger UARFCN;
@property NSInteger RSSNR;
@property NSInteger RSRQ;
@property NSString *CellType;
@property NSMutableArray *neighbourCells;

-(BOOL)isConnected; //check connection
-(NSString*)getConnectionType; //include WiFi and Radio
-(NSString*)getRadioConnectionType; //radio only

-(RatType*)getRatType;
-(NetworkType*)getNetworkType;

-(id)init;
-(id)initWithPrivateCellInfo;
@end
