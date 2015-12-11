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

@interface czzSettingsCentre () <NSCoding, czzURLDownloaderProtocol>
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
@synthesize nightyMode;
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
        nightyMode = NO;
        userDefShouldCleanCaches = NO;
        shouldAllowOpenBlockedThread = YES;
        
        donationLink = @"";
        threads_per_page = 10;
        response_per_page = 20;
        
        //Dart settings
        should_allow_dart = NO;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_configuration" ofType:@"json"];

        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        [self parseJSONData:JSONData];
        
#ifdef DEBUG
#warning DEBUGGING NEW API
        return self;
#endif
        [self scheduleRefreshSettings];
        // Restore previous settings
        [self restoreSettings];
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

-(BOOL)saveSettings {
    if ([NSKeyedArchiver archiveRootObject:self toFile:self.settingsFile]) {
        DLog(@"Settings saved to file: %@", self.settingsFile);
        return YES;
    } else {
        DLog(@"Settings can not be saved! Settings file: %@", self.settingsFile);
        return NO;
    }
}


- (BOOL)restoreSettings {
    @try {
        czzSettingsCentre *archivedSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:self.settingsFile];
        if (archivedSettings && archivedSettings.class == self.class)
        {
            NSArray *properties = [PropertyUtil classPropsFor:self.class].allKeys;
            if (properties.count > 0) {
                for (NSString *propertyName in properties) {
                    if ([self respondsToSelector:NSSelectorFromString(propertyName)]) {
                        @try {
                            if ([propertyName isEqualToString:@"description"] || [propertyName isEqualToString:@"debugDescription"] || [propertyName isEqualToString:@"hash"] || [propertyName isEqualToString:@"superclass"]) {
                                // Do nothing
                            } else {
                                [self setValue:[archivedSettings valueForKey:propertyName] forKey:propertyName];
                            }
                        }
                        @catch (NSException *exception) {
                            DLog(@"%@", exception);
                        }
                    }
                    else
                        DLog(@"%@ - cannot be restored:", propertyName);
                }
            }
            return YES;
        } else {
            DLog(@"failed to restore files");
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return NO;
}

-(void)downloadSettings {
    NSString *configurationURL = CONFIGURATION_URL;
    urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:configurationURL] delegate:self startNow:YES];
}
-(void)parseJSONData:(NSData*)jsonData {
    NSError *error;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

    if (error) {
        DLog(@"%@", error);
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
        DLog(@"%@", exception);
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
            DLog(@"settings updated from remote server");
            if (message.length > 0) {
                [AppDelegate showToast:message];
            }
        }
    }
}

#pragma mark - NSCoding delegate

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:shouldUseRemoteConfiguration forKey:@"shouldUseRemoteConfiguration"];
    [aCoder encodeBool:shouldEnableBlacklistFiltering forKey:@"shouldEnableBlacklistFiltering"];
    [aCoder encodeBool:shouldDisplayImage forKey:@"shouldDisplayImage"];
    [aCoder encodeBool:shouldDisplayThumbnail forKey:@"shouldDisplayThumbnail"];
    [aCoder encodeBool:shouldDisplayContent forKey:@"shouldDisplayContent"];
    [aCoder encodeObject:shouldHideImageInForums forKey:@"shouldHideImageInForums"];
    [aCoder encodeDouble:configuration_refresh_interval forKey:@"configuration_refresh_interval"];
    [aCoder encodeDouble:blacklist_refresh_interval forKey:@"blacklist_refresh_interval"];
    [aCoder encodeDouble:forum_list_refresh_interval forKey:@"forum_list_refresh_interval"];
    [aCoder encodeDouble:notification_refresh_interval forKey:@"notification_refresh_interval"];
    [aCoder encodeInteger:threads_per_page forKey:@"threads_per_page"];
    [aCoder encodeInteger:response_per_page forKey:@"response_per_page"];
    [aCoder encodeObject:thread_format forKey:@"thread_format"];
    [aCoder encodeObject:forum_list_url forKey:@"forum_list_url"];
    [aCoder encodeObject:ac_host forKey:@"ac_host"];
    [aCoder encodeObject:a_isle_host forKey:@"a_isle_host"];
    [aCoder encodeObject:database_host forKey:@"database_host"];
    [aCoder encodeObject:thread_list_host forKey:@"thread_list_host"];
    [aCoder encodeObject:thread_content_host forKey:@"thread_content_host"];
    [aCoder encodeObject:quote_thread_host forKey:@"quote_thread_host"];
    [aCoder encodeObject:image_host forKey:@"image_host"];
    [aCoder encodeObject:thumbnail_host forKey:@"thumbnail_host"];
    [aCoder encodeObject:message forKey:@"message"];
    [aCoder encodeObject:donationLink forKey:@"donationLink"];
    [aCoder encodeBool:userDefShouldDisplayThumbnail forKey:@"userDefShouldDisplayThumbnail"];
    [aCoder encodeBool:userDefShouldShowOnScreenCommand forKey:@"userDefShouldShowOnScreenCommand"];
    [aCoder encodeBool:userDefShouldAutoOpenImage forKey:@"userDefShouldAutoOpenImage"];
//    [aCoder encodeBool:userDefShouldCacheData forKey:@"userDefShouldCacheData"];
    [aCoder encodeBool:userDefShouldHighlightPO forKey:@"userDefShouldHighlightPO"];
    [aCoder encodeBool:userDefShouldUseBigImage forKey:@"userDefShouldUseBigImage"];
    [aCoder encodeBool:nightyMode forKey:@"nightyMode"];
    [aCoder encodeBool:userDefShouldCleanCaches forKey:@"userDefShouldCleanCaches"];
    
    //new settings at short version 2.0.1
    [aCoder encodeObject:forum_list_detail_url forKey:@"forum_list_detail_url"];
    [aCoder encodeObject:reply_post_url forKey:@"reply_post_url"];
    [aCoder encodeObject:create_new_post_url forKey:@"create_new_post_url"];
    [aCoder encodeObject:report_post_placeholder forKey:@"report_post_placeholder"];
    [aCoder encodeObject:share_post_url forKey:@"share_post_url"];
    [aCoder encodeObject:thread_url forKey:@"thread_url"];
    [aCoder encodeObject:get_forum_info_url forKey:@"get_forum_info_url"];
    
    //dart settings
    [aCoder encodeBool:should_allow_dart forKey:@"shouldAllowDart"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.shouldUseRemoteConfiguration = [aDecoder decodeBoolForKey:@"shouldUseRemoteConfiguration"];
        self.shouldEnableBlacklistFiltering = [aDecoder decodeBoolForKey:@"shouldEnableBlacklistFiltering"];
        self.shouldDisplayImage = [aDecoder decodeBoolForKey:@"shouldDisplayImage"];
        self.shouldDisplayThumbnail = [aDecoder decodeBoolForKey:@"shouldDisplayThumbnail"];
        self.shouldDisplayContent = [aDecoder decodeBoolForKey:@"shouldDisplayContent"];
        self.shouldHideImageInForums = [aDecoder decodeObjectForKey:@"shouldHideImageInForums"];
        self.configuration_refresh_interval = [aDecoder decodeDoubleForKey:@"configuration_refresh_interval"];
        self.blacklist_refresh_interval = [aDecoder decodeDoubleForKey:@"blacklist_refresh_interval"];
        self.forum_list_refresh_interval = [aDecoder decodeDoubleForKey:@"forum_list_refresh_interval"];
        self.notification_refresh_interval = [aDecoder decodeDoubleForKey:@"notification_refresh_interval"];
        self.threads_per_page = [aDecoder decodeIntegerForKey:@"threads_per_page"];
        self.response_per_page = [aDecoder decodeIntegerForKey:@"response_per_page"];
        self.thread_format = [aDecoder decodeObjectForKey:@"thread_format"];
        self.forum_list_url = [aDecoder decodeObjectForKey:@"forum_list_url"];
        self.ac_host = [aDecoder decodeObjectForKey:@"ac_host"];
        self.a_isle_host = [aDecoder decodeObjectForKey:@"a_isle_host"];
        self.database_host = [aDecoder decodeObjectForKey:@"database_host"];
        self.thread_list_host = [aDecoder decodeObjectForKey:@"thread_list_host"];
        self.thread_content_host = [aDecoder decodeObjectForKey:@"thread_content_host"];
        self.quote_thread_host = [aDecoder decodeObjectForKey:@"quote_thread_host"];
        self.image_host = [aDecoder decodeObjectForKey:@"image_host"];
        self.thumbnail_host = [aDecoder decodeObjectForKey:@"thumbnail_host"];
        self.donationLink = [aDecoder decodeObjectForKey:@"donationLink"];
        self.message = [aDecoder decodeObjectForKey:@"message"];
        self.userDefShouldDisplayThumbnail = [aDecoder decodeBoolForKey:@"userDefShouldDisplayThumbnail"];
        self.userDefShouldShowOnScreenCommand = [aDecoder decodeBoolForKey:@"userDefShouldShowOnScreenCommand"];
        self.userDefShouldAutoOpenImage = [aDecoder decodeBoolForKey:@"userDefShouldAutoOpenImage"];
//        self.userDefShouldCacheData = [aDecoder decodeBoolForKey:@"userDefShouldCacheData"];
        self.userDefShouldHighlightPO = [aDecoder decodeBoolForKey:@"userDefShouldHighlightPO"];
        self.userDefShouldUseBigImage = [aDecoder decodeBoolForKey:@"userDefShouldUseBigImage"];
        
        self.nightyMode = [aDecoder decodeBoolForKey:@"nightyMode"];
        self.userDefShouldCleanCaches = [aDecoder decodeBoolForKey:@"userDefShouldCleanCaches"];
        self.should_allow_dart = [aDecoder decodeBoolForKey:@"shouldAllowDart"];
        //new settings at short version 2.0.1
        self.forum_list_detail_url = [aDecoder decodeObjectForKey:@"forum_list_detail_url"];
        self.reply_post_url = [aDecoder decodeObjectForKey:@"reply_post_url"];
        self.create_new_post_url = [aDecoder decodeObjectForKey:@"create_new_post_url"];
        self.report_post_placeholder = [aDecoder decodeObjectForKey:@"report_post_placeholder"];
        self.share_post_url = [aDecoder decodeObjectForKey:@"share_post_url"];
        self.thread_url = [aDecoder decodeObjectForKey:@"thread_url"];
        self.get_forum_info_url = [aDecoder decodeObjectForKey:@"get_forum_info_url"];

    }
    return self;
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
    if (self.nightyMode)
        return [UIColor colorWithRed:252/255.0f green:160/255.0f blue:30/255.0f alpha:1.0f];
    return [UIColor blackColor];
}

-(UIColor *)viewBackgroundColour {
    if (self.nightyMode)
        return [UIColor colorWithRed:20/255.0f green:20/255.0f blue:20/255.0f alpha:1.0f];
    return [UIColor whiteColor];
}

-(UIColor *)barTintColour {
    return [UIColor colorWithRed:252/255. green:103/255. blue:61/255. alpha:1.0];
}

-(UIColor *)tintColour {
    if (self.nightyMode)
        return [UIColor lightTextColor];
    return [UIColor whiteColor];
}
@end
