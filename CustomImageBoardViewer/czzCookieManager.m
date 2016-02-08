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
@property (nonatomic, strong) NSHTTPCookieStorage *cookieStorage;
@property (nonatomic, strong) NSMutableArray *acCookies;
@end

@implementation czzCookieManager

//http://ano-zhai-so.n1.yun.tf:8999/Home/Api/getCookie
-(instancetype)init {
    self = [super init];
    if (self) {
        self.archivedCookies = [NSMutableArray new];
        [self restoreArchivedCookies];
        [self getCookieIfHungry];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidEnterBackgroundNotification)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Life cycle.
- (void)handleDidEnterBackgroundNotification {
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);
    [self archiveCookiesToFile];
}

-(void)getCookieIfHungry {
    if (self.acCookies.count > 0) {
        DDLogDebug(@"%s: no need for anymore cookies.", __PRETTY_FUNCTION__);
        return;
    }
    DDLogDebug(@"current cookie empty, try to eat a cookie");
    NSString *getCookieURLString = [[settingCentre a_isle_host] stringByAppendingPathComponent:[NSString stringWithFormat:@"/Home/Api/getCookie?deviceid=%@", [UIDevice currentDevice].identifierForVendor.UUIDString]];

    czzURLDownloader *urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:getCookieURLString] delegate:self startNow:YES shouldUseDefaultCookit:NO];
    [urlDownloader start];
}

-(void)setACCookie:(NSHTTPCookie *)cookie ForURL:(NSURL *)url {
    if (!cookie)
    {
        DDLogDebug(@"incoming cookie is nil");
        return;
    }
    [self.cookieStorage setCookies:@[cookie] forURL:url mainDocumentURL:nil];
}

-(void)deleteCookie:(NSHTTPCookie *)cookie {
    [self.cookieStorage deleteCookie:cookie];
}

-(NSArray *)currentACCookies {
    return [self.acCookies copy];
}

-(NSHTTPCookie *)currentInUseCookie {
    NSArray *allCookies = [self.cookieStorage cookiesForURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
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
    [self.archivedCookies addObject:cookie];
    [self archiveCookiesToFile];
}

-(void)deleteArchiveCookie:(NSHTTPCookie *)cookie {
    [self.archivedCookies removeObject:cookie];
    [self archiveCookiesToFile];
}

-(void)archiveCookiesToFile {
    [NSKeyedArchiver archiveRootObject:self.archivedCookies toFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE]];
    DDLogDebug(@"Archived cookies saved.");
    if (self.currentInUseCookie) {
        [NSKeyedArchiver archiveRootObject:self.currentInUseCookie toFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:IN_USE_COOKIE_FILE]];
        DDLogDebug(@"In use cookie saved.");
    }
}

-(void)restoreArchivedCookies {
    // Restore the archived cookies.
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE]]) {
        id archivedCookies = [NSKeyedUnarchiver unarchiveObjectWithFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE]];
        if ([archivedCookies isKindOfClass:[NSMutableArray class]]){
            self.archivedCookies = archivedCookies;
            DDLogDebug(@"Archived cookies restored.");
        }
    }
    // Restore the in use cookie.
    NSString *inUseCookieFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:IN_USE_COOKIE_FILE];
    if ([[NSFileManager defaultManager] fileExistsAtPath:inUseCookieFile]) {
        NSHTTPCookie *inUseCookie = [NSKeyedUnarchiver unarchiveObjectWithFile:inUseCookieFile];
        if (inUseCookie) {
            [self addValueAsCookie:inUseCookie.properties[cookieName]];
            DDLogDebug(@"In use cookie restored.");
        }
    }
}

#pragma mark - czzURLDownloaderDelegate
- (void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    NSString *result = [[NSString alloc] initWithData:downloadedData encoding:NSUTF8StringEncoding];
    if (successed && [result containsString:@"ok"]) {
        DDLogDebug(@"I ate a cookie!");
    } else {
        DDLogDebug(@"can't find a cookie to eat!");
    }

}

#pragma mark - Getters

- (NSMutableArray *)acCookies {
    NSMutableArray *cookies = [NSMutableArray new];
    for (NSHTTPCookie *cookie in [self.cookieStorage cookies]) {
        if ([cookie.name.lowercaseString isEqualToString:cookieName.lowercaseString]) {
            DDLogDebug(@"%@", cookie);
            [cookies addObject:cookie];
        }
    }
    return cookies;
}

- (NSHTTPCookieStorage *)cookieStorage {
    [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    return [NSHTTPCookieStorage sharedHTTPCookieStorage];
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
