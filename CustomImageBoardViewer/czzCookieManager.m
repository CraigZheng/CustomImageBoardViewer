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
@property (nonatomic, readonly) NSString *archiveFilePath;
@property (nonatomic, readonly) NSString *inUseFilePath;
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
    [self saveCurrentState];
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
    DDLogDebug(@"Set in use cookie:");
    DDLogDebug(@"Cookie: %@", cookie);
    DDLogDebug(@"URL: %@", url);
    [self.cookieStorage setCookies:@[cookie]
                            forURL:[NSURL URLWithString:[settingCentre a_isle_host]]
                   mainDocumentURL:nil];
    [self saveCurrentState];
}

-(void)deleteCookie:(NSHTTPCookie *)cookie {
    [self.cookieStorage deleteCookie:cookie];
    [self saveCurrentState];
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
    [self saveCurrentState];
}

-(void)deleteArchiveCookie:(NSHTTPCookie *)cookie {
    [self.archivedCookies removeObject:cookie];
    [self saveCurrentState];
}

-(void)saveCurrentState {
    // Delete the old copies of archives...
    [[NSFileManager defaultManager] removeItemAtPath:self.archiveFilePath error:nil];
    // Create a new file for the cookies.
    [[NSFileManager defaultManager] createFileAtPath:self.archiveFilePath
                                            contents:nil
                                          attributes:@{NSFileProtectionKey:NSFileProtectionNone}];
    [NSKeyedArchiver archiveRootObject:self.archivedCookies toFile:self.archiveFilePath];
    DDLogDebug(@"%s: archive", __PRETTY_FUNCTION__);
    [[NSFileManager defaultManager] removeItemAtPath:self.inUseFilePath error:nil];
    if (self.currentInUseCookie) {
        // Create a new file for the in use cookie.
        [[NSFileManager defaultManager] createFileAtPath:self.inUseFilePath
                                                contents:nil
                                              attributes:@{NSFileProtectionKey:NSFileProtectionNone}];
        [NSKeyedArchiver archiveRootObject:self.currentInUseCookie toFile:self.inUseFilePath];
        DDLogDebug(@"%s: in use", __PRETTY_FUNCTION__);
    }
}

-(void)restoreArchivedCookies {
    // Try to restore the legacy file, and delete it afterward.
    NSString *legacyFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE];
    if ([[NSFileManager defaultManager] fileExistsAtPath:legacyFile]) {
        DDLogDebug(@"Need to restore legacy file for %@", NSStringFromClass(self.class));
        NSError *error;
        [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:self.archiveFilePath]
                                           withItemAtURL:[NSURL fileURLWithPath:legacyFile]
                                          backupItemName:@"LegacyCookie.dat"
                                                 options:0
                                        resultingItemURL:nil
                                                   error:&error];
        if (error) {
            DDLogDebug(@"%s: %@", __PRETTY_FUNCTION__, error);
        }
        [[NSFileManager defaultManager] removeItemAtPath:legacyFile error:&error];
        if (error) {
            DDLogDebug(@"%s: %@", __PRETTY_FUNCTION__, error);
        }        
    }
    // Restore the archived cookies.
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.archiveFilePath]) {
        id archivedCookies = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archiveFilePath];
        if ([archivedCookies isKindOfClass:[NSMutableArray class]]){
            self.archivedCookies = archivedCookies;
            DDLogDebug(@"%s: in archive", __PRETTY_FUNCTION__);
        }
    }
    // Restore the in use cookie - if the NSCookieStorage does not have an AC cookie.
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.inUseFilePath] &&
        !self.currentInUseCookie) {
        NSHTTPCookie *inUseCookie = [NSKeyedUnarchiver unarchiveObjectWithFile:self.inUseFilePath];
        [self setACCookie:inUseCookie
                   ForURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
        DDLogDebug(@"%s: in use", __PRETTY_FUNCTION__);
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

- (NSString *)cookieFolder {
    NSString *cookieFolder = [[czzAppDelegate documentFolder] stringByAppendingPathComponent:@"Cookies"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cookieFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:cookieFolder
                                  withIntermediateDirectories:NO
                                                   attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                                        error:nil];
        DDLogDebug(@"Create document folder: %@", cookieFolder);
    }
    return cookieFolder;
}

- (NSString *)archiveFilePath {
    return [self.cookieFolder stringByAppendingPathComponent:COOKIES_ARCHIVE_FILE];
}

- (NSString *)inUseFilePath {
    return [self.cookieFolder stringByAppendingPathComponent:IN_USE_COOKIE_FILE];
}

- (NSMutableArray *)acCookies {
    NSMutableArray *acCookies = [NSMutableArray new];
    NSArray *cookies = [self.cookieStorage cookies];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name.lowercaseString isEqualToString:cookieName.lowercaseString]) {
            [acCookies addObject:cookie];
        }
    }
    DDLogDebug(@"Currently have %ld ac cookies", (long)acCookies.count);
    return acCookies;
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
