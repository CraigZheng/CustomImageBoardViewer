//
//  czzSettingsCentre.m
//  CustomImageBoardViewer
//
//  Created by Craig on 7/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzSettingsCentre.h"
#import "PropertyUtil.h"
#import <objc/runtime.h>
#import "czzAppDelegate.h"
#import "czzURLDownloader.h"
#import <UIKit/UIKit.h>

static NSString * const kDisplayThumbnail = @"kDisplayThumbnail";
static NSString * const kShowOnScreenCommand = @"kShowOnScreenCommand";
static NSString * const kAutoOpenImage = @"kAutoOpenImage";
static NSString * const kHighLightPO = @"kHighLightPO";
static NSString * const kCacheData = @"kCacheData";
static NSString * const kBigImageMode = @"kBigImageMode";
static NSString * const kNightyMode = @"kNightyMode";
static NSString * const kAutoClean = @"kAutoClean";
static NSString * const kAutoDownloadImage = @"kAutoDownloadImage";

@interface czzSettingsCentre () <czzURLDownloaderProtocol>
@property NSTimer *refreshSettingsTimer;
@property (nonatomic) NSString *settingsFile;
@property czzURLDownloader *urlDownloader;
@end

@implementation czzSettingsCentre
@synthesize settingsFile;
@synthesize refreshSettingsTimer;
@synthesize shouldDisplayContent, shouldDisplayImage, shouldDisplayThumbnail, shouldEnableBlacklistFiltering, shouldUseRemoteConfiguration, shouldHideImageInForums;
@synthesize configuration_refresh_interval, blacklist_refresh_interval, forum_list_refresh_interval, notification_refresh_interval;
@synthesize database_host;
@synthesize a_isle_host, thread_content_host, threads_per_page, thread_format, thread_list_host, response_per_page, quote_thread_host;
@synthesize message, image_host, ac_host, forum_list_url, thumbnail_host;
@synthesize userDefShouldAutoOpenImage, userDefShouldCacheData, userDefShouldDisplayThumbnail, userDefShouldHighlightPO, userDefShouldShowOnScreenCommand ,userDefShouldUseBigImage, userDefShouldCleanCaches;
@synthesize userDefNightyMode;
@synthesize should_allow_dart;
@synthesize donationLink;
@synthesize shouldAllowOpenBlockedThread;
@synthesize urlDownloader;
//settings added at short version 2.0.1
@synthesize forum_list_detail_url, reply_post_url, create_new_post_url, report_post_placeholder, share_post_url, thread_url, get_forum_info_url;

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

-(instancetype)init {
    self = [super init];
    if (self) {
        //default settings
        userDefShouldAutoOpenImage = YES;
        userDefShouldDisplayThumbnail = YES;
        userDefShouldCacheData = YES;
        userDefShouldHighlightPO = YES;
        userDefShouldShowOnScreenCommand = YES;
        userDefShouldUseBigImage = NO;
        userDefNightyMode = NO;
        userDefShouldCleanCaches = NO;
        self.userDefShouldAutoDownloadImage = NO;
        shouldAllowOpenBlockedThread = YES;
        
        donationLink = @"";
        threads_per_page = 10;
        response_per_page = 20;
        
        //Dart settings
        should_allow_dart = NO;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_configuration" ofType:@"json"];

        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        [self parseJSONData:JSONData];
        
        [self restoreSettings];
#ifdef DEBUG
#warning DEBUGGING NEW API
        return self;
#endif
        [self scheduleRefreshSettings];
        // Restore previous settings
    }
    return self;
}

-(void)scheduleRefreshSettings {
    [self downloadSettings];
    if (configuration_refresh_interval <= 60) //fail safe
        return;
    if (refreshSettingsTimer.isValid) {
        [refreshSettingsTimer invalidate];
    }
#ifdef DEBUG
    //in debug build, refresh the settings every 5 minutes
    configuration_refresh_interval = 60 * 5;
#endif
    refreshSettingsTimer = [NSTimer scheduledTimerWithTimeInterval:configuration_refresh_interval target:self selector:@selector(downloadSettings) userInfo:nil repeats:YES];
}

-(void)saveSettings {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:userDefShouldDisplayThumbnail forKey:kDisplayThumbnail];
    [userDefault setBool:userDefShouldShowOnScreenCommand forKey:kShowOnScreenCommand];
    [userDefault setBool:userDefShouldAutoOpenImage forKey:kAutoOpenImage];
    [userDefault setBool:userDefShouldCacheData forKey:kCacheData];
    [userDefault setBool:userDefShouldHighlightPO forKey:kHighLightPO];
    [userDefault setBool:userDefShouldUseBigImage forKey:kBigImageMode];
    [userDefault setBool:userDefNightyMode forKey:kNightyMode];
    [userDefault setBool:userDefShouldCleanCaches forKey:kAutoClean];
    [userDefault setBool:self.userDefShouldAutoDownloadImage forKey:kAutoDownloadImage];
    [userDefault synchronize];
}


- (void)restoreSettings {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if ([userDefault objectForKey:kDisplayThumbnail]) {
        userDefShouldDisplayThumbnail = [userDefault boolForKey:kDisplayThumbnail];
    }
    if ([userDefault objectForKey:kShowOnScreenCommand]) {
        userDefShouldShowOnScreenCommand = [userDefault boolForKey:kShowOnScreenCommand];
    }
    if ([userDefault objectForKey:kAutoOpenImage]) {
        userDefShouldAutoOpenImage = [userDefault boolForKey:kAutoOpenImage];
    }
    if ([userDefault objectForKey:kCacheData]) {
        userDefShouldCacheData = [userDefault boolForKey:kCacheData];
    }
    if ([userDefault objectForKey:kHighLightPO]) {
        userDefShouldHighlightPO = [userDefault boolForKey:kHighLightPO];
    }
    if ([userDefault objectForKey:kBigImageMode]) {
        userDefShouldUseBigImage = [userDefault boolForKey:kBigImageMode];
    }
    if ([userDefault objectForKey:kNightyMode]) {
        userDefNightyMode = [userDefault boolForKey:kNightyMode];
    }
    if ([userDefault objectForKey:kAutoClean]) {
        userDefShouldCleanCaches = [userDefault boolForKey:kAutoClean];
    }
    self.userDefShouldAutoDownloadImage = [userDefault boolForKey:kAutoDownloadImage];
}

-(void)downloadSettings {
    NSString *configurationURL = CONFIGURATION_URL;
    urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:configurationURL] delegate:self startNow:YES];
}

-(void)parseJSONData:(NSData*)jsonData {
    NSError *error;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

    if (error) {
        DDLogDebug(@"%@", error);
        return;
    }
    @try {
        
        shouldUseRemoteConfiguration = [[jsonObject objectForKey:@"shouldUseRemoteConfiguration"] boolValue];
        shouldEnableBlacklistFiltering = [[jsonObject objectForKey:@"shouldEnableBlacklistFiltering"] boolValue];
        shouldDisplayImage = [[jsonObject objectForKey:@"shouldDisplayImage"] boolValue];
        shouldDisplayThumbnail = [[jsonObject objectForKey:@"shouldDisplayThumbnail"] boolValue];
        shouldDisplayContent = [[jsonObject objectForKey:@"shouldDisplayContent"] boolValue];
        shouldHideImageInForums = [jsonObject objectForKey:@"shouldHideImageInForms"];
        shouldAllowOpenBlockedThread = [[jsonObject objectForKey:@"shouldAllowOpenBlockedThread"] boolValue];
        configuration_refresh_interval = [[jsonObject objectForKey:@"configuration_refresh_interval"] floatValue];
        blacklist_refresh_interval = [[jsonObject objectForKey:@"blacklist_refresh_interval"] floatValue];
        forum_list_refresh_interval = [[jsonObject objectForKey:@"forum_list_refresh_interval"] floatValue];
        notification_refresh_interval = [[jsonObject objectForKey:@"notification_refresh_interval"] floatValue];
        threads_per_page = [[jsonObject objectForKey:@"threads_per_page"] integerValue];
        response_per_page = [[jsonObject objectForKey:@"response_per_page"] integerValue];
        thread_format = [jsonObject objectForKey:@"thread_format"];
        database_host = [jsonObject objectForKey:@"database_host"];
        forum_list_url = [jsonObject objectForKey:@"forum_list_url"];
        ac_host = [jsonObject objectForKey:@"ac_host"];
        a_isle_host = [jsonObject objectForKey:@"a_isle_host"];
        thread_list_host = [jsonObject objectForKey:@"thread_list_host"];
        thread_content_host = [jsonObject objectForKey:@"thread_content_host"];
        quote_thread_host = [jsonObject objectForKey:@"quote_thread_host"];
        image_host = [jsonObject objectForKey:@"image_host"];
        thumbnail_host = [jsonObject objectForKey:@"thumbnail_host"];
        donationLink = [jsonObject objectForKey:@"donation_link"];
        message = [jsonObject objectForKey:@"message"];
        
        //dart integration
        should_allow_dart = [[jsonObject objectForKey:@"shouldAllowDart"] boolValue];
        
        //new settings at short version 2.0.1
        forum_list_detail_url = [jsonObject objectForKey:@"forum_list_detail_url"];
        reply_post_url = [jsonObject objectForKey:@"reply_post_url"];
        create_new_post_url = [jsonObject objectForKey:@"create_new_post_url"];
        report_post_placeholder = [jsonObject objectForKey:@"report_post_placeholder"];
        share_post_url = [jsonObject objectForKey:@"share_post_url"];
        thread_url = [jsonObject objectForKey:@"thread_url"];
        get_forum_info_url = [jsonObject objectForKey:@"get_forum_info_url"];
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
}

-(NSString *)settingsFile {
    NSString* libraryPath = [czzAppDelegate libraryFolder];
    return [libraryPath stringByAppendingPathComponent:@"Settings.dat"];
}

#pragma mark - czzURLDownloaderDelegate
-(void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    if (successed) {
        if (downloadedData) {
            [self parseJSONData:downloadedData];
            [self saveSettings]; //save settings from remote
            DDLogDebug(@"settings updated from remote server");
            if (message.length > 0) {
                [AppDelegate showToast:message];
            }
        }
    }
}

-(UIFont *)contentFont {
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        /* Device is iPad */
        return [UIFont systemFontOfSize:18];
    }
    return [UIFont systemFontOfSize:16];
}

-(UIColor *)contentTextColour {
    if (self.userDefNightyMode)
        return [UIColor colorWithRed:252/255.0f green:160/255.0f blue:30/255.0f alpha:1.0f];
    return [UIColor blackColor];
}

-(UIColor *)viewBackgroundColour {
    if (self.userDefNightyMode)
        return [UIColor colorWithRed:20/255.0f green:20/255.0f blue:20/255.0f alpha:1.0f];
    return [UIColor whiteColor];
}

-(UIColor *)barTintColour {
    return [UIColor colorWithRed:252/255. green:103/255. blue:61/255. alpha:1.0];
}

- (UIColor *)transparentBackgroundColour {
    return [[UIColor grayColor] colorWithAlphaComponent:0.2];
}

-(UIColor *)tintColour {
    if (self.userDefNightyMode)
        return [UIColor lightTextColor];
    return [UIColor whiteColor];
}
@end
