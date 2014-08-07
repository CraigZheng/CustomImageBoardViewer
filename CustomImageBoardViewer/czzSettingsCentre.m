//
//  czzSettingsCentre.m
//  CustomImageBoardViewer
//
//  Created by Craig on 7/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzSettingsCentre.h"

@interface czzSettingsCentre ()
@property NSTimer *refreshSettingsTimer;
@end

@implementation czzSettingsCentre
@synthesize refreshSettingsTimer;
@synthesize shouldDisplayContent, shouldDisplayImage, shouldDisplayThumbnail, shouldEnableBlacklistFiltering, shouldUseRemoteConfiguration;
@synthesize configuration_refresh_interval, blacklist_refresh_interval, forum_list_refresh_interval, notification_refresh_interval;
@synthesize thread_content_host, threads_per_page, thread_format, thread_list_host;
@synthesize message, image_host, ac_host, forum_list_url;

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
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_configuration" ofType:@"json"];
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        [self parseJSONData:JSONData];
        [self scheduleRefreshSettings];
        
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

-(void)saveSettings {
    
}

- (void)restoreSettings {
    
}

-(void)downloadSettings {
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *configurationURL = [NSString stringWithFormat:@"http://civ.atwebpages.com/php/remote_configuration.php?version=%@", versionString];
    [NSURLConnection sendAsynchronousRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:configurationURL]]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [self parseJSONData:data];
                               });
                           }];
}

-(void)parseJSONData:(NSData*)jsonData {
    NSError *error;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    shouldUseRemoteConfiguration = [[jsonObject objectForKey:@"shouldUseRemoteConfiguration"] boolValue];
    shouldEnableBlacklistFiltering = [[jsonObject objectForKey:@"shouldEnableBlacklistFiltering"] boolValue];
    shouldDisplayImage = [[jsonObject objectForKey:@"shouldDisplayImage"] boolValue];
    shouldDisplayThumbnail = [[jsonObject objectForKey:@"shouldDisplayThumbnail"] boolValue];
    shouldDisplayContent = [[jsonObject objectForKey:@"shouldDisplayContent"] boolValue];
    configuration_refresh_interval = [[jsonObject objectForKey:@"configuration_refresh_interval"] floatValue];
    blacklist_refresh_interval = [[jsonObject objectForKey:@"blacklist_refresh_interval"] floatValue];
    forum_list_refresh_interval = [[jsonObject objectForKey:@"forum_list_refresh_interval"] floatValue];
    notification_refresh_interval = [[jsonObject objectForKey:@"notification_refresh_interval"] floatValue];
    threads_per_page = [[jsonObject objectForKey:@"threads_per_page"] integerValue];
    thread_format = [jsonObject objectForKey:@"thread_format"];
    forum_list_url = [jsonObject objectForKey:@"forum_list_url"];
    ac_host = [jsonObject objectForKey:@"ac_host"];
    thread_list_host = [jsonObject objectForKey:@"thread_list_host"];
    thread_content_host = [jsonObject objectForKey:@"thread_content_host"];
    image_host = [jsonObject objectForKey:@"image_host"];
    message = [jsonObject objectForKey:@"message"];

}
@end
