//
//  czzACTokenUtil.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzACTokenUtil.h"

NSString * const cookieName = @"userhash";

@implementation czzACTokenUtil

+(NSHTTPCookie *)createCookieWithValue:(NSString *)value forURL:(NSURL *)url {
    if (!value && !url)
        return nil;
    NSDictionary *cookieDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[url host], NSHTTPCookieDomain,
                                      @"/", NSHTTPCookiePath,
                                      cookieName, NSHTTPCookieName,
                                      value, NSHTTPCookieValue,
                                      [NSDate distantFuture], NSHTTPCookieExpires, // Forever valid.
                                      nil];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieDictionary];
    return cookie;
}

+(NSString *)createJsonFileWithCookie:(NSHTTPCookie *)cookie {
    if (cookie) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cookie.properties options:NSJSONWritingPrettyPrinted error:&error];
        if (!error)
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        else
            DDLogDebug(@"%@", error);
    }
    return nil;
}
@end
