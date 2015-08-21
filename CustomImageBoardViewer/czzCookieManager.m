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

@interface czzCookieManager()
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
    __block NSMutableURLRequest *urlRequest = [NSMutableURLRequest new];
    NSString *getCookieURLString = [NSString stringWithFormat:@"http://ano-zhai-so.n1.yun.tf:8999/Home/Api/getCookie?deviceid=%@", [UIDevice currentDevice].identifierForVendor.UUIDString];

    urlRequest.URL = [NSURL URLWithString:getCookieURLString];
    [urlRequest setValue:@"HAvfun Client" forHTTPHeaderField:@"User-Agent"];

    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if ([(NSHTTPURLResponse*)response statusCode] == 200) {
            DLog(@"I ate a cookie!");
        } else {
            DLog(@"can't find a cookie to eat!");
        }
    }];
}

-(void)refreshACCookies {
    NSMutableArray *cookies = [NSMutableArray new];
    
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([cookie.name.lowercaseString isEqualToString:@"userhash".lowercaseString]) {
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
        if ([cookie.name.lowercaseString isEqualToString:@"username".lowercaseString]) {
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
