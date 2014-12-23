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
#import <UIKit/UIKit.h>

@interface czzSettingsCentre () <NSCoding>
@property NSTimer *refreshSettingsTimer;
@property (nonatomic) NSString *settingsFile;
@end

@implementation czzSettingsCentre
@synthesize settingsFile;
@synthesize refreshSettingsTimer;
@synthesize shouldDisplayContent, shouldDisplayImage, shouldDisplayThumbnail, shouldEnableBlacklistFiltering, shouldUseRemoteConfiguration, shouldHideImageInForums;
@synthesize configuration_refresh_interval, blacklist_refresh_interval, forum_list_refresh_interval, notification_refresh_interval;
@synthesize a_isle_host, thread_content_host, threads_per_page, thread_format, thread_list_host;
@synthesize message, image_host, ac_host, forum_list_url, thumbnail_host;
@synthesize userDefShouldAutoOpenImage, userDefShouldCacheData, userDefShouldDisplayThumbnail, userDefShouldHighlightPO, userDefShouldShowOnScreenCommand ,userDefShouldUseBigImage;
@synthesize nightyMode;
@synthesize autoCleanImageCache;
@synthesize shouldAllowDart;
@synthesize shouldAllowOpenBlockedThread;

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

-(id)init {
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
        autoCleanImageCache = NO;
        shouldAllowOpenBlockedThread = YES;
        
        //Dart settings
        shouldAllowDart = NO;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_configuration" ofType:@"json"];
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        [self parseJSONData:JSONData];
        [self scheduleRefreshSettings];
        //restore previous settings
        [self restoreSettings];
    }
    return self;
}

-(void)scheduleRefreshSettings {
    if (configuration_refresh_interval <= 60) //fail safe
        return;
    if (refreshSettingsTimer.isValid) {
        [refreshSettingsTimer invalidate];
    }
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

-(void)getPropertyTypeWithName:(NSString*)propertyName {
    NSString *classString = NSStringFromClass([[self valueForKey:propertyName] class]);

    DLog(@"class: %@", classString);
}

- (BOOL)restoreSettings {
    @try {
        czzSettingsCentre *archivedSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:self.settingsFile];
        if (archivedSettings && archivedSettings.class == self.class)
        {
            NSArray *properties = [PropertyUtil classPropsFor:self.class].allKeys;
            if (properties.count > 0) {
                for (NSString *propertyName in properties) {
                    [self setValue:[archivedSettings valueForKey:propertyName] forKey:propertyName];
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
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifdef DEBUG
    versionString = @"DEBUG";
#endif
    NSString *configurationURL = [NSString stringWithFormat:@"%@?version=%@", CONFIGURATION_URL, versionString];
    [NSURLConnection sendAsynchronousRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:configurationURL]]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (data) {
                                       [self parseJSONData:data];
                                       [self saveSettings]; //save settings from remote
                                       DLog(@"settings updated from remote server");
                                       if (message.length > 0) {
                                           [[czzAppDelegate sharedAppDelegate] showToast:message];
                                       }
                                   }
                               });
                           }];

}

-(void)parseJSONData:(NSData*)jsonData {
    NSError *error;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        DLog(@"%@", error);
        return;
    }
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
    thread_format = [jsonObject objectForKey:@"thread_format"];
    forum_list_url = [jsonObject objectForKey:@"forum_list_url"];
    ac_host = [jsonObject objectForKey:@"ac_host"];
    a_isle_host = [jsonObject objectForKey:@"a_isle_host"];
    thread_list_host = [jsonObject objectForKey:@"thread_list_host"];
    thread_content_host = [jsonObject objectForKey:@"thread_content_host"];
    image_host = [jsonObject objectForKey:@"image_host"];
    thumbnail_host = [jsonObject objectForKey:@"thumbnail_host"];
    message = [jsonObject objectForKey:@"message"];
    
    //dart integration
    shouldAllowDart = [[jsonObject objectForKey:@"shouldAllowDart"] boolValue];
    
    
}

-(NSString *)settingsFile {
    NSString* libraryPath = [czzAppDelegate libraryFolder];
    return [libraryPath stringByAppendingPathComponent:@"Settings.dat"];
}

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
    [aCoder encodeObject:thread_format forKey:@"thread_format"];
    [aCoder encodeObject:forum_list_url forKey:@"forum_list_url"];
    [aCoder encodeObject:ac_host forKey:@"ac_host"];
    [aCoder encodeObject:a_isle_host forKey:@"a_isle_host"];
    [aCoder encodeObject:thread_list_host forKey:@"thread_list_host"];
    [aCoder encodeObject:thread_content_host forKey:@"thread_content_host"];
    [aCoder encodeObject:image_host forKey:@"image_host"];
    [aCoder encodeObject:thumbnail_host forKey:@"thumbnail_host"];
    [aCoder encodeObject:message forKey:@"message"];
    [aCoder encodeBool:userDefShouldDisplayThumbnail forKey:@"userDefShouldDisplayThumbnail"];
    [aCoder encodeBool:userDefShouldShowOnScreenCommand forKey:@"userDefShouldShowOnScreenCommand"];
    [aCoder encodeBool:userDefShouldAutoOpenImage forKey:@"userDefShouldAutoOpenImage"];
    [aCoder encodeBool:userDefShouldCacheData forKey:@"userDefShouldCacheData"];
    [aCoder encodeBool:userDefShouldHighlightPO forKey:@"userDefShouldHighlightPO"];
    [aCoder encodeBool:userDefShouldUseBigImage forKey:@"userDefShouldUseBigImage"];
    [aCoder encodeBool:nightyMode forKey:@"nightyMode"];
    [aCoder encodeBool:autoCleanImageCache forKey:@"autoCleanImageCache"];
    [aCoder encodeBool:shouldAllowDart forKey:@"shouldAllowDart"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
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
        self.thread_format = [aDecoder decodeObjectForKey:@"thread_format"];
        self.forum_list_url = [aDecoder decodeObjectForKey:@"forum_list_url"];
        self.ac_host = [aDecoder decodeObjectForKey:@"ac_host"];
        self.a_isle_host = [aDecoder decodeObjectForKey:@"a_isle_host"];
        self.thread_list_host = [aDecoder decodeObjectForKey:@"thread_list_host"];
        self.thread_content_host = [aDecoder decodeObjectForKey:@"thread_content_host"];
        self.image_host = [aDecoder decodeObjectForKey:@"image_host"];
        self.thumbnail_host = [aDecoder decodeObjectForKey:@"thumbnail_host"];
        self.message = [aDecoder decodeObjectForKey:@"message"];
        self.userDefShouldDisplayThumbnail = [aDecoder decodeBoolForKey:@"userDefShouldDisplayThumbnail"];
        self.userDefShouldShowOnScreenCommand = [aDecoder decodeBoolForKey:@"userDefShouldShowOnScreenCommand"];
        self.userDefShouldAutoOpenImage = [aDecoder decodeBoolForKey:@"userDefShouldAutoOpenImage"];
        self.userDefShouldCacheData = [aDecoder decodeBoolForKey:@"userDefShouldCacheData"];
        self.userDefShouldHighlightPO = [aDecoder decodeBoolForKey:@"userDefShouldHighlightPO"];
        self.userDefShouldUseBigImage = [aDecoder decodeBoolForKey:@"userDefShouldUseBigImage"];
        
        self.nightyMode = [aDecoder decodeBoolForKey:@"nightyMode"];
        self.autoCleanImageCache = [aDecoder decodeBoolForKey:@"autoCleanImageCache"];
        self.shouldAllowDart = [aDecoder decodeBoolForKey:@"shouldAllowDart"];
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
