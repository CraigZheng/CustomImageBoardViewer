//
//  czzCookieManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzCookieManager.h"
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"
#import "czzACTokenUtil.h"
#import "czzURLDownloader.h"

@interface czzCookieManager() <czzURLDownloaderProtocol>
@property NSHTTPCookieStorage *cookieStorage;
@property NSMutableArray *acCookies;
@end

@implementation czzCookieManager
@synthesize cookieStorage;
@synthesize acCookies;
@synthesize archivedCookies;

//http://ano-zhai-so.n1.yun.tf:8999/Home/Api/getCookie
-(instancetype)init {
    self = [super init];
    if (self) {
        acCookies = [NSMutableArray new];
        archivedCookies = [NSMutableArray new];
        NSMutableArray *tempArray = [self restoreArchivedCookies];
        if (tempArray) {
            archivedCookies = tempArray;
        } else
            [self refreshACCookies];
        cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        cookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        [self getCookieIfHungry];
    }
    
    return self;
}


-(void)getCookieIfHungry {
    if (acCookies.count > 0)
        return;
    DLog(@"current cookie empty, try to eat a cookie");
    NSString *getCookieURLString = [[settingCentre a_isle_host] stringByAppendingPathComponent:[NSString stringWithFormat:@"/Home/Api/getCookie?deviceid=%@", [UIDevice currentDevice].identifierForVendor.UUIDString]];

    czzURLDownloader *urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:getCookieURLString] delegate:self startNow:YES shouldUseDefaultCookit:NO];
    [urlDownloader start];
}

-(void)refreshACCookies {
    NSMutableArray *cookies = [NSMutableArray new];
    
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([cookie.name.lowercaseString isEqualToString:cookieName.lowercaseString]) {
            DLog(@"%@", cookie);
            [cookies addObject:cookie];
        }
    }
    acCookies = cookies;
}

-(void)setACCookie:(NSHTTPCookie *)cookie ForURL:(NSURL *)url {
    if (!cookie)
    {
        DLog(@"incoming cookie is nil");
        return;
    }
    [cookieStorage setCookies:@[cookie] forURL:url mainDocumentURL:nil];
}

-(void)deleteCookie:(NSHTTPCookie *)cookie {
    [cookieStorage deleteCookie:cookie];
}

-(NSArray *)currentACCookies {
    return acCookies;
}

-(NSHTTPCookie *)currentInUseCookie {
    NSArray *allCookies = [cookieStorage cookiesForURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
    NSHTTPCookie *inUseCookie;
    for (NSHTTPCookie *cookie in allCookies) {
        if ([cookie.name.lowercaseString isEqualToString:cookieName.lowercaseString]) {
            inUseCookie = cookie;
            break;
        }
    }
    
    return inUseCookie;
}

-(BOOL)addValueAsCookie:(NSString *)cookieValue {
    NSHTTPCookie *newCookie = [czzACTokenUtil createCookieWithValue:cookieValue forURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
    if (newCookie) {
        [self archiveCookie:newCookie];
        return YES;
    }
    return NO;
}

-(void)archiveCookie:(NSHTTPCookie *)cookie {
    [archivedCookies addObject:cookie];
    [self archiveCookiesToFile];
}

-(void)deleteArchiveCookie:(NSHTTPCookie *)cookie {
    [archivedCookies removeObject:cookie];
    [self archiveCookiesToFile];
}

-(void)archiveCookiesToFile {
    [NSKeyedArchiver archiveRootObject:archivedCookies toFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE]];
}

-(NSMutableArray*)restoreArchivedCookies {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE]]) {
        id archiedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE]];
        if ([archiedArray isKindOfClass:[NSMutableArray class]]){
            return archiedArray;
        }

    }
    return nil;
}

#pragma mark - czzURLDownloaderDelegate
- (void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    NSString *result = [[NSString alloc] initWithData:downloadedData encoding:NSUTF8StringEncoding];
    if (successed && [result containsString:@"ok"]) {
        DLog(@"I ate a cookie!");
    } else {
        DLog(@"can't find a cookie to eat!");
    }

}

+ (instancetype)sharedInstance
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
