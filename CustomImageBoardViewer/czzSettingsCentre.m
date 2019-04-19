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
#import "czzLaunchPopUpNotification.h"
#import "czzLaunchPopUpNotificationViewController.h"
#import <Google/Analytics.h>
#import <UIKit/UIKit.h>

#import "CustomImageBoardViewer-Swift.h"

static NSString * const kDisplayThumbnail = @"kDisplayThumbnail";
static NSString * const kShowOnScreenCommand = @"kShowOnScreenCommand";
static NSString * const kAutoOpenImage = @"kAutoOpenImage";
static NSString * const kHighLightPO = @"kHighLightPO";
static NSString * const kCacheData = @"kCacheData";
static NSString * const kBigImageMode = @"kBigImageMode";
static NSString * const kNightyMode = @"kNightyMode";
static NSString * const kAutoClean = @"kAutoClean";
static NSString * const kAutoDownloadImage = @"kAutoDownloadImage";
static NSString * const kShouldCollapseLongContent = @"kShouldCollapseLongContent";
static NSString * const kTextSize = @"kTextSize";
static NSString * const kShouldShowImageManagerButton = @"kShouldShowImageManagerButton";
static NSString * const kShouldShowDraft = @"userDefShouldShowDraft";
static NSString * const kActiveHost = @"userDefActiveHost";
static NSString * const kRecordPageNumber = @"userDefRecordPageNumber";

NSString * const settingsChangedNotification = @"settingsChangedNotification";

@interface czzSettingsCentre () <czzURLDownloaderProtocol>
@property NSTimer *refreshSettingsTimer;
@property (nonatomic) NSString *settingsFile;
@property czzURLDownloader *urlDownloader;
@property (nonatomic, strong) NSData *configurationJSONData;
@property (strong, readwrite) NSString *ac_isle_host;
@property (strong, readwrite) NSString *bt_isle_host;
@end

@implementation czzSettingsCentre
@synthesize settingsFile;
@synthesize refreshSettingsTimer;
@synthesize shouldDisplayContent, shouldDisplayImage, shouldDisplayThumbnail, shouldEnableBlacklistFiltering, shouldUseRemoteConfiguration, shouldHideImageInForums;
@synthesize configuration_refresh_interval, blacklist_refresh_interval, forum_list_refresh_interval, notification_refresh_interval;
@synthesize database_host;
@synthesize activeHost, thread_content_host, threads_per_page, thread_format, thread_list_host, response_per_page, quote_thread_host;
@synthesize message, image_host, ac_host, forum_list_url, thumbnail_host;
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
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_configuration" ofType:@"json"];
    NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    _configurationJSONData = JSONData;
    _userDefShouldAutoOpenImage = YES;
    _userDefShouldDisplayThumbnail = YES;
    _userDefShouldCacheData = YES;
    _userDefShouldHighlightPO = YES;
    _userDefShouldShowOnScreenCommand = YES;
    _userDefShouldUseBigImage = NO;
    _userDefNightyMode = NO;
    _userDefShouldCleanCaches = NO;
    _userDefShouldAutoDownloadImage = NO;
    _userDefShouldCollapseLongContent = NO;
    _userDefShouldShowDraft = YES;
    shouldAllowOpenBlockedThread = YES;
    _threadTextSize = TextSizeDefault;
    _shouldShowImageManagerButton = YES;
    _ignoredThreadIDs = [NSArray new];
    _userDefActiveHost = SettingsHostAC;
    _userDefRecordPageNumber = YES;
    
    donationLink = @"";
    threads_per_page = 10;
    response_per_page = 20;
    _long_thread_threshold = 200;
    _upload_image_pixel_limit = 5595136; // iPad pro resolution: 2732 x 2048;
    should_allow_dart = NO;
    
    [self restoreSettings];
    [self downloadSettings];
  }
  return self;
}

-(void)scheduleRefreshSettings {
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
  [userDefault setBool:self.userDefShouldDisplayThumbnail forKey:kDisplayThumbnail];
  [userDefault setBool:self.userDefShouldShowOnScreenCommand forKey:kShowOnScreenCommand];
  [userDefault setBool:self.userDefShouldAutoOpenImage forKey:kAutoOpenImage];
  [userDefault setBool:self.userDefShouldCacheData forKey:kCacheData];
  [userDefault setBool:self.userDefShouldHighlightPO forKey:kHighLightPO];
  [userDefault setBool:self.userDefShouldUseBigImage forKey:kBigImageMode];
  [userDefault setBool:self.userDefNightyMode forKey:kNightyMode];
  [userDefault setBool:self.userDefShouldCleanCaches forKey:kAutoClean];
  [userDefault setBool:self.userDefShouldAutoDownloadImage forKey:kAutoDownloadImage];
  [userDefault setBool:self.userDefShouldCollapseLongContent forKey:kShouldCollapseLongContent];
  [userDefault setInteger:self.threadTextSize forKey:kTextSize];
  [userDefault setBool:self.shouldShowImageManagerButton forKey:kShouldShowImageManagerButton];
  [userDefault setBool:self.userDefShouldShowDraft forKey:kShouldShowDraft];
  [userDefault setInteger:self.userDefActiveHost forKey:kActiveHost];
  [userDefault setBool:self.userDefRecordPageNumber forKey:kRecordPageNumber];
  [userDefault synchronize];
  // Post a notification about the settings changed.
  [[NSNotificationCenter defaultCenter] postNotificationName:settingsChangedNotification
                                                      object:nil];
}


- (void)restoreSettings {
  NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
  if ([userDefault objectForKey:kDisplayThumbnail]) {
    self.userDefShouldDisplayThumbnail = [userDefault boolForKey:kDisplayThumbnail];
  }
  if ([userDefault objectForKey:kShowOnScreenCommand]) {
    self.userDefShouldShowOnScreenCommand = [userDefault boolForKey:kShowOnScreenCommand];
  }
  if ([userDefault objectForKey:kAutoOpenImage]) {
    self.userDefShouldAutoOpenImage = [userDefault boolForKey:kAutoOpenImage];
  }
  if ([userDefault objectForKey:kCacheData]) {
    self.userDefShouldCacheData = [userDefault boolForKey:kCacheData];
  }
  if ([userDefault objectForKey:kHighLightPO]) {
    self.userDefShouldHighlightPO = [userDefault boolForKey:kHighLightPO];
  }
  if ([userDefault objectForKey:kBigImageMode]) {
    self.userDefShouldUseBigImage = [userDefault boolForKey:kBigImageMode];
  }
  if ([userDefault objectForKey:kNightyMode]) {
    self.userDefNightyMode = [userDefault boolForKey:kNightyMode];
  }
  if ([userDefault objectForKey:kAutoClean]) {
    self.userDefShouldCleanCaches = [userDefault boolForKey:kAutoClean];
  }
  if ([userDefault objectForKey:kShouldCollapseLongContent]) {
    self.userDefShouldCollapseLongContent = [userDefault boolForKey:kShouldCollapseLongContent];
  }
  if ([userDefault objectForKey:kTextSize]) {
    self.threadTextSize = [userDefault integerForKey:kTextSize];
  }
  self.userDefShouldAutoDownloadImage = [userDefault boolForKey:kAutoDownloadImage];
  if ([userDefault objectForKey:kShouldShowImageManagerButton]) {
    self.shouldShowImageManagerButton = [userDefault boolForKey:kShouldShowImageManagerButton];
  }
  if ([userDefault objectForKey:kShouldShowDraft]) {
    self.userDefShouldShowDraft = [userDefault boolForKey:kShouldShowDraft];
  }
  if ([userDefault objectForKey:kActiveHost]) {
    self.userDefActiveHost = [userDefault integerForKey:kActiveHost];
  } else {
    self.userDefActiveHost = SettingsHostAC;
  }
  if ([userDefault objectForKey:kRecordPageNumber]) {
    self.userDefRecordPageNumber = [userDefault boolForKey:kRecordPageNumber];
  }
  
  // Google analytics.
  id<GAITracker> defaultTracker = [[GAI sharedInstance] defaultTracker];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Display Thumbnail"
                                                                label:[self stringWithBoolean:self.userDefShouldDisplayThumbnail]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Display Quick Scroll"
                                                                label:[self stringWithBoolean:self.userDefShouldShowOnScreenCommand]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Auto Open Downloaded Image"
                                                                label:[self stringWithBoolean:self.userDefShouldAutoOpenImage]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Big Image Mode"
                                                                label:[self stringWithBoolean:self.userDefShouldUseBigImage]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Nighty Mode"
                                                                label:[self stringWithBoolean:self.userDefNightyMode]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Auto Download Image"
                                                                label:[self stringWithBoolean:self.userDefShouldAutoDownloadImage]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Collapse Long Content"
                                                                label:[self stringWithBoolean:self.userDefShouldCollapseLongContent]
                                                                value:@1] build]];
  [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Show Image Manager Button"
                                                                label:[self stringWithBoolean:self.shouldShowImageManagerButton]
                                                                value:@1] build]];
  
}

- (NSString*)stringWithBoolean:(Boolean)b {
    return b ? @"On" : @"Off";
}

-(void)downloadSettings {
    NSString *configurationURL = CONFIGURATION_URL;
    urlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:configurationURL] delegate:self startNow:YES];
}

#pragma mark - Parsing JSON.

-(void)parseJSONData:(NSData*)jsonData {
}

-(NSString *)settingsFile {
    NSString* libraryPath = [czzAppDelegate libraryFolder];
    return [libraryPath stringByAppendingPathComponent:@"Settings.dat"];
}

#pragma mark - czzURLDownloaderDelegate
-(void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    if (successed) {
        if (downloadedData) {
          self.configurationJSONData = downloadedData;
          [self saveSettings];
            if (message.length) {
                [MessagePopup showMessagePopupWithTitle:nil
                                                message:message
                                                 layout:MessagePopupLayoutMessageView
                                                  theme:MessagePopupThemeInfo
                                               position:MessagePopupPresentationStyleTop
                                            buttonTitle:nil
                                    buttonActionHandler:nil];
            }
            // Perform a short task to get the notification content when the app is in the foreground.
            if (self.popup_notification_link.length) {
                NSURL *notificationURL = [NSURL URLWithString:self.popup_notification_link];
                if (notificationURL) {
                    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:notificationURL]
                                                       queue:[NSOperationQueue currentQueue]
                                           completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                                               if ([(NSHTTPURLResponse *)response statusCode] == 200 && data) {
                                                   NSString *jsonString = [[NSString alloc] initWithData:data
                                                                                                encoding:NSUTF8StringEncoding];
                                                   czzLaunchPopUpNotification *notification = [[czzLaunchPopUpNotification alloc] initWithJson:jsonString];
                                                   if (notification) {
                                                       czzLaunchPopUpNotificationViewController *popUpViewController = [[UIStoryboard storyboardWithName:@"LaunchPopUpNotification"
                                                                                                                                                  bundle:[NSBundle mainBundle]] instantiateInitialViewController];
                                                       popUpViewController.popUpNotification = notification;
                                                       [popUpViewController tryShow];
                                                   }
                                               }
                                           }];
                }
            }
        }
    }
    // Success or not, I need to schedule the periodic refresh.
    [self scheduleRefreshSettings];
}

-(UIFont *)contentFont {
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        /* Device is iPad */
        return [UIFont systemFontOfSize:18 * [self fontScale]];
    }
    return [UIFont systemFontOfSize:16 * [self fontScale]];
}

- (CGFloat)fontScale {
    switch (self.threadTextSize) {
        case TextSizeBig:
            return 1.3;
            break;
        case TextSizeExtraBig:
            return 1.6;
            break;
        case TextSizeSmall:
            return 0.8;
            break;
        default:
            return 1;
            break;
    }
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

#pragma mark - Setters
- (void)setUserDefActiveHost:(SettingsHost)userDefActiveHost {
  _userDefActiveHost = userDefActiveHost;
  [self validateJSONConfiguration];
}

- (void)setConfigurationJSONData:(NSData *)configurationJSONData {
  _configurationJSONData = configurationJSONData;
  [self validateJSONConfiguration];
}

- (void)validateJSONConfiguration {
  if (self.configurationJSONData) {
    NSError *error;
    __block NSDictionary *jsonObject;
    NSArray<NSDictionary<NSString *, NSObject *> *> *jsonArray = [NSJSONSerialization JSONObjectWithData:self.configurationJSONData options:NSJSONReadingMutableContainers error:&error];
    [jsonArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      NSString *configurationName = obj[@"configuration_name"];
      if ([configurationName isEqualToString:@"AC"]) {
        self.ac_isle_host = [obj objectForKey:@"a_isle_host"];
      }
      if ([configurationName isEqualToString:@"BT"]) {
        self.bt_isle_host = [obj objectForKey:@"a_isle_host"];
      }
      switch (self.userDefActiveHost) {
        case SettingsHostAC:
          if ([configurationName isEqualToString:@"AC"]) {
            jsonObject = obj;
          }
          break;
        case SettingsHostBT:
          if ([configurationName isEqualToString:@"BT"]) {
            jsonObject = obj;
          }
          break;
        default:
          break;
      }
    }];
    if (!error && jsonObject) {
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
        activeHost = [jsonObject objectForKey:@"a_isle_host"];
        thread_list_host = [jsonObject objectForKey:@"thread_list_host"];
        thread_content_host = [jsonObject objectForKey:@"thread_content_host"];
        quote_thread_host = [jsonObject objectForKey:@"quote_thread_host"];
        image_host = [jsonObject objectForKey:@"image_host"];
        thumbnail_host = [jsonObject objectForKey:@"thumbnail_host"];
        self.imageCDNConfigurationHost = jsonObject[@"image_cdn_configuration"];
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
        self.popup_notification_link = [jsonObject objectForKey:@"popup_notification_link"];
        self.empty_title = [jsonObject objectForKey:@"empty_title"];
        self.empty_username = [jsonObject objectForKey:@"empty_username"];
        self.sensitive_keyword = [jsonObject objectForKey:@"sensitive_keyword"];
        self.success_keyword = [jsonObject objectForKey:@"success_keyword"];
        self.share_image_only_keyword = [jsonObject objectForKey:@"share_image_only_keyword"];
        self.popular_threads_link = [jsonObject objectForKey:@"popular_threads_link"];
        self.long_thread_threshold = [[jsonObject objectForKey:@"long_thread_threshold"] integerValue];
        self.reply_post_placeholder = [jsonObject objectForKey:@"reply_post_placeholder"];
        self.shouldShowEmoPackPicker = [[jsonObject objectForKey:@"shouldShowEmoPackPicker"] boolValue];
        self.timeline_url = [jsonObject objectForKey:@"timeline_url"];
        NSArray *ignoredThreadIDs = [jsonObject objectForKey:@"ignored_thread_ids"];
        if (ignoredThreadIDs.count) {
          NSMutableArray *threadIDs = [NSMutableArray new];
          for (NSObject *threadID in ignoredThreadIDs) {
            if ([threadID isKindOfClass:[NSNumber class]]) {
              [threadIDs addObject:threadID];
            }
          }
          self.ignoredThreadIDs = threadIDs;
        } else {
          self.ignoredThreadIDs = [NSArray new];
        }
          [self validateImageCDN];
        if ([jsonObject objectForKey:@"upload_image_pixel_limit"]) {
          self.upload_image_pixel_limit = [[jsonObject objectForKey:@"upload_image_pixel_limit"] integerValue];
        }
      }
      @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
      }
    }
  }
}
@end
