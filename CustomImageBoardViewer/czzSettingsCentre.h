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
@property BOOL shouldUseRemoteConfiguration;
@property BOOL shouldEnableBlacklistFiltering;
@property BOOL shouldDisplayImage;
@property BOOL shouldDisplayThumbnail;
@property BOOL shouldDisplayContent;
@property BOOL shouldAllowOpenBlockedThread;
@property NSArray *shouldHideImageInForums;
@property NSTimeInterval configuration_refresh_interval;
@property NSTimeInterval blacklist_refresh_interval;
@property NSTimeInterval forum_list_refresh_interval;
@property NSTimeInterval notification_refresh_interval;
@property NSInteger threads_per_page;
@property NSInteger response_per_page;
@property NSString *thread_format;
@property NSString *forum_list_url;
//these are the new settings at version 2.0.1(short version)
@property NSString *forum_list_detail_url;
@property NSString *reply_post_url;
@property NSString *create_new_post_url;
@property NSString *report_post_placeholder;
@property NSString *share_post_url;
@property NSString *thread_url;
@property NSString *get_forum_info_url;
//new settins end here
@property NSString *ac_host;
@property NSString *a_isle_host;
@property NSString *thread_list_host;
@property NSString *thread_content_host;
@property NSString *image_host;
@property NSString *thumbnail_host;
@property NSString *message;
@property NSString *donationLink;
//User settings
@property BOOL userDefShouldDisplayThumbnail;
@property BOOL userDefShouldShowOnScreenCommand;
@property BOOL userDefShouldAutoOpenImage;
@property BOOL userDefShouldCacheData;
@property BOOL userDefShouldHighlightPO;
@property BOOL userDefShouldUseBigImage;
@property BOOL nightyMode;
@property BOOL autoCleanImageCache;
//Debug settings
@property BOOL should_allow_dart;

+ (id)sharedInstance;
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
