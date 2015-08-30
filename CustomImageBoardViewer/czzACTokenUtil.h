//
//  czzACTokenUtil.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const cookieName = @"userhash";

@interface czzACTokenUtil : NSObject

+(NSHTTPCookie*)createCookieWithValue:(NSString*)value forURL:(NSURL*)url;
+(NSString*)createJsonFileWithCookie:(NSHTTPCookie*)cookie;

@end
