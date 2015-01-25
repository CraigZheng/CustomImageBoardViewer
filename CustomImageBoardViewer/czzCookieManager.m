//
//  czzCookieManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzCookieManager.h"
#import "czzSettingsCentre.h"
#import "czzACTokenUtil.h"

@interface czzCookieManager()
@property NSHTTPCookieStorage *cookieStorage;
@property NSMutableArray *acCookies;
@end

@implementation czzCookieManager
@synthesize cookieStorage;
@synthesize acCookies;

-(instancetype)init {
    self = [super init];
    if (self) {
        cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    }
    
    return self;
}

-(void)refreshACCookies {
    NSMutableArray *cookies = [NSMutableArray new];
    
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([cookie.name.lowercaseString isEqualToString:@"userId".lowercaseString]) {
            DLog(@"%@", cookie);
            [cookies addObject:cookie];
        }
    }
    acCookies = cookies;
}

-(void)setACCookie:(NSHTTPCookie *)cookie ForURL:(NSURL *)url {
    [cookieStorage setCookies:@[cookie] forURL:url mainDocumentURL:nil];
}


+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

@end
