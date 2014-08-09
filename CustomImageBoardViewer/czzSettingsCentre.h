//
//  czzSettingsCentre.h
//  CustomImageBoardViewer
//
//  Created by Craig on 7/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CONFIGURATION_URL @"http://civ.atwebpages.com/remote_configuration.json"

@interface czzSettingsCentre : NSObject

//Remote configurations
@property BOOL shouldUseRemoteConfiguration;
@property BOOL shouldEnableBlacklistFiltering;
@property BOOL shouldDisplayImage;
@property BOOL shouldDisplayThumbnail;
@property BOOL shouldDisplayContent;
@property NSArray *shouldHideImageInForums;
@property NSTimeInterval configuration_refresh_interval;
@property NSTimeInterval blacklist_refresh_interval;
@property NSTimeInterval forum_list_refresh_interval;
@property NSTimeInterval notification_refresh_interval;
@property NSInteger threads_per_page;
@property NSString *thread_format;
@property NSString *forum_list_url;
@property NSString *ac_host;
@property NSString *a_isle_host;
@property NSString *thread_list_host;
@property NSString *thread_content_host;
@property NSString *image_host;
@property NSString *thumbnail_host;
@property NSString *message;
//User settings
@property BOOL userDefShouldDisplayThumbnail;
@property BOOL userDefShouldShowOnScreenCommand;
@property BOOL userDefShouldAutoOpenImage;
@property BOOL userDefShouldCacheData;
@property BOOL userDefShouldHightlightPO;


+ (id)sharedInstance;
-(void)downloadSettings;
-(void)saveSettings;
-(void)restoreSettings;
@end
