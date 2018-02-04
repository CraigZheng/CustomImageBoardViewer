//
//  czzSettingsCentre.h
//  CustomImageBoardViewer
//
//  Created by Craig on 7/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define settingCentre [czzSettingsCentre sharedInstance]

#import <Foundation/Foundation.h>

#define CONFIGURATION_URL @"http://my-realm.com/php/remote_configuration.php"

extern NSString * const settingsChangedNotification;
extern NSString * const kAutoCleanPeriod;

typedef enum : NSInteger {
    TextSizeDefault = 0,
    TextSizeSmall = 1,
    TextSizeBig = 2,
    TextSizeExtraBig = 3
} ThreadViewTextSize;

typedef NS_ENUM(NSInteger, SettingsHost) {
  SettingsHostAC,
  SettingsHostBT
};

@interface czzSettingsCentre : NSObject

//Remote configurations
@property (assign, nonatomic) BOOL shouldUseRemoteConfiguration;
@property (assign, nonatomic) BOOL shouldEnableBlacklistFiltering;
@property (assign, nonatomic) BOOL shouldDisplayImage;
@property (assign, nonatomic) BOOL shouldDisplayThumbnail;
@property (assign, nonatomic) BOOL shouldDisplayContent;
@property (assign, nonatomic) BOOL shouldAllowOpenBlockedThread;
@property (strong, nonatomic) NSArray *shouldHideImageInForums;
@property (assign, nonatomic) NSTimeInterval configuration_refresh_interval;
@property (assign, nonatomic) NSTimeInterval blacklist_refresh_interval;
@property (assign, nonatomic) NSTimeInterval forum_list_refresh_interval;
@property (assign, nonatomic) NSTimeInterval notification_refresh_interval;
@property (assign, nonatomic) NSInteger threads_per_page;
@property (assign, nonatomic) NSInteger response_per_page;
@property (strong, nonatomic) NSString *thread_format;
@property (strong, nonatomic) NSString *forum_list_url;
@property (strong, nonatomic) NSString *database_host;
//these are the new settings at version 2.0.1(short version)
@property (strong, nonatomic) NSString *forum_list_detail_url;
@property (strong, nonatomic) NSString *reply_post_url;
@property (strong, nonatomic) NSString *create_new_post_url;
@property (strong, nonatomic) NSString *report_post_placeholder;
@property (strong, nonatomic) NSString *reply_post_placeholder;
@property (strong, nonatomic) NSString *share_post_url;
@property (strong, nonatomic) NSString *thread_url;
@property (strong, nonatomic) NSString *get_forum_info_url;
//new settins end here
@property (strong, nonatomic) NSString *empty_title;
@property (strong, nonatomic) NSString *empty_username;
@property (strong, nonatomic) NSString *sensitive_keyword;
@property (strong, nonatomic) NSString *success_keyword;
@property (strong, nonatomic) NSString *share_image_only_keyword;
@property (strong, nonatomic) NSString *ac_host;
@property (strong, nonatomic) NSString *a_isle_host;
@property (strong, nonatomic) NSString *thread_list_host;
@property (strong, nonatomic) NSString *thread_content_host;
@property (strong, nonatomic) NSString *quote_thread_host;
@property (strong, nonatomic) NSString *image_host;
@property (strong, nonatomic) NSString *thumbnail_host;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSString *donationLink;
@property (strong, nonatomic) NSString *popular_threads_link;
@property (assign, nonatomic) NSInteger long_thread_threshold;
@property (assign, nonatomic) NSInteger upload_image_pixel_limit;
@property (assign, nonatomic) BOOL shouldShowEmoPackPicker;
@property (strong, nonatomic) NSArray<NSNumber *> *ignoredThreadIDs;
@property (strong, nonatomic) NSString *timeline_url;
//User settings
@property (assign, nonatomic) BOOL userDefShouldDisplayThumbnail;
@property (assign, nonatomic) BOOL userDefShouldShowOnScreenCommand;
@property (assign, nonatomic) BOOL userDefShouldAutoOpenImage;
@property (assign, nonatomic) BOOL userDefShouldCacheData;
@property (assign, nonatomic) BOOL userDefShouldHighlightPO;
@property (assign, nonatomic) BOOL userDefShouldUseBigImage;
@property (assign, nonatomic) BOOL userDefNightyMode;
@property (assign, nonatomic) BOOL userDefShouldCleanCaches;
@property (assign, nonatomic) BOOL userDefShouldAutoDownloadImage;
@property (assign, nonatomic) BOOL userDefShouldCollapseLongContent;
@property (assign, nonatomic) BOOL userDefShouldShowDraft;
@property (assign, nonatomic) SettingsHost userDefActiveHost;
@property (assign, nonatomic) BOOL userDefRecordPageNumber;
@property (assign, nonatomic) ThreadViewTextSize threadTextSize;
@property (assign, nonatomic) BOOL shouldShowImageManagerButton;
//Debug settings
@property (assign, nonatomic) BOOL should_allow_dart;
// Popup notification
@property (strong, nonatomic) NSString *popup_notification_link;

+ (instancetype)sharedInstance;
-(void)downloadSettings;
-(void)saveSettings;
-(void)restoreSettings;

-(UIFont*)contentFont;
-(UIColor*)contentTextColour;
-(UIColor*)viewBackgroundColour;
-(UIColor*)transparentBackgroundColour;

//UI constants
-(UIColor*)barTintColour;
-(UIColor*)tintColour;
@end
