//
//  czzCookieManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#define CookieManager [czzCookieManager sharedInstance]

#import <Foundation/Foundation.h>

@interface czzCookieManager : NSObject
+(id)sharedInstance;

-(NSArray*)currentACCookies;
-(void)refreshACCookies;
-(void)setACCookie:(NSHTTPCookie*)cookie ForURL:(NSURL*)url;
-(void)deleteCookie:(NSHTTPCookie*)cookie;
@end
