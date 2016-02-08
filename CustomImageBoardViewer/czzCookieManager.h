//
//  czzCookieManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#define CookieManager [czzCookieManager sharedInstance]
#define COOKIES_ARCHIVE_FILE @"COOKIES_ARCHIVE_FILE.dat"
#define IN_USE_COOKIE_FILE @"IN_USE_COOKIE_FILE.dat"

#import <Foundation/Foundation.h>

@interface czzCookieManager : NSObject
@property NSMutableArray *archivedCookies;

-(NSArray*)currentACCookies;
-(NSHTTPCookie*)currentInUseCookie;
-(BOOL)addValueAsCookie:(NSString*)cookieValue;
-(void)archiveCookie:(NSHTTPCookie*)cookie;
-(void)deleteArchiveCookie:(NSHTTPCookie*)cookie;
-(void)setACCookie:(NSHTTPCookie*)cookie ForURL:(NSURL*)url;
-(void)deleteCookie:(NSHTTPCookie*)cookie;

+(instancetype)sharedInstance;

@end
