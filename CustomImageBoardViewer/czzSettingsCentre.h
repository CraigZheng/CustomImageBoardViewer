//
//  czzSettingsCentre.h
//  CustomImageBoardViewer
//
//  Created by Craig on 7/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define settingCentre [czzSettingsCentre sharedInstance]

#import <Foundation/Foundation.h>

#define CONFIGURATION_URL @"http://www.my-realm.com/php/remote_configuration.php"

@interface czzSettingsCentre : NSObject

//Remote configurations
@property (assign, nonatomic) BOOL shouldUseRemoteConfiguration;
@property (assign, nonatomic) BOOL shouldEnableBlacklistFiltering;
@property (assign, nonatomic) BOOL shouldDisplayImage;
@property (assign, nonatomic) BOOL shouldDisplayThumbnail;
@property (assign, nonatomic) BOOL shouldDisplayContent;
@property (assign, nonatomic) BOOL shouldAllowOpenBlockedThread;
@property (strong, nonatomic) NSArray *shouldHideImageInForums;
@property NSTimeInterval configuration_refresh_interval;
@property NSTimeInterval blacklist_refresh_interval;
@property NSTimeInterval forum_list_refresh_interval;
@property NSTimeInterval notification_refresh_interval;
@property NSInteger threads_per_page;
@property NSInteger response_per_page;
@property (strong, nonatomic) NSString *thread_format;
@property (strong, nonatomic) NSString *forum_list_url;
//these are the new settings at version 2.0.1(short version)
@property (strong, nonatomic) NSString *forum_list_detail_url;
@property (strong, nonatomic) NSString *reply_post_url;
@property (strong, nonatomic) NSString *create_new_post_url;
@property (strong, nonatomic) NSString *report_post_placeholder;
@property (strong, nonatomic) NSString *share_post_url;
@property (strong, nonatomic) NSString *thread_url;
@property (strong, nonatomic) NSString *get_forum_info_url;
//new settins end here
@property (strong, nonatomic) NSString *ac_host;
@property (strong, nonatomic) NSString *a_isle_host;
@property (strong, nonatomic) NSString *thread_list_host;
@property (strong, nonatomic) NSString *thread_content_host;
@property (strong, nonatomic) NSString *image_host;
@property (strong, nonatomic) NSString *thumbnail_host;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSString *donationLink;
//User settings
@property (assign, nonatomic) BOOL userDefShouldDisplayThumbnail;
@property (assign, nonatomic) BOOL userDefShouldShowOnScreenCommand;
@property (assign, nonatomic) BOOL userDefShouldAutoOpenImage;
@property (assign, nonatomic) BOOL userDefShouldCacheData;
@property (assign, nonatomic) BOOL userDefShouldHighlightPO;
@property (assign, nonatomic) BOOL userDefShouldUseBigImage;
@property (assign, nonatomic) BOOL nightyMode;
@property (assign, nonatomic) BOOL autoCleanImageCache;
//Debug settings
@property (assign, nonatomic) BOOL should_allow_dart;

+ (instancetype)sharedInstance;
-(void)downloadSettings;
-(BOOL)saveSettings;
-(BOOL)restoreSettings;

-(UIFont*)contentFont;
-(UIColor*)contentTextColour;
-(UIColor*)viewBackgroundColour;

//UI constants
-(UIColor*)barTintColour;
-(UIColor*)tintColour;
@end
