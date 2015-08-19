//
//  czzForumManager.m
//  CustomImageBoardViewer
//
//  Created by Craig on 19/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzForumManager.h"
#import "czzXMLDownloader.h"
#import "czzSettingsCentre.h"

@interface czzForumManager() <czzXMLDownloaderDelegate>
@property czzXMLDownloader *forumDownloader;
@property (copy) void (^completionHandler) (BOOL, NSError*);
@end

@implementation czzForumManager

- (void)updateForums:(void (^)(BOOL, NSError *))completionHandler {
    if (self.forumDownloader)
        [self.forumDownloader stop];
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifdef DEBUG
    versionString = @"DEBUG";
#endif
    NSString *forumString = [[settingCentre forum_list_url] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [NSString stringWithFormat:@"%@-%@", bundleIdentifier, versionString]]];
    NSLog(@"Forum config URL: %@", forumString);
    self.forumDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];

}

- (NSArray *)forumGroups {
    if (!_forumGroups) {
        _forumGroups = [NSMutableArray new];
    }
    return _forumGroups;
}

#pragma mark - czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData {
    if (self.completionHandler) {
        self.completionHandler(successed, nil);
    }
}

+ (instancetype)sharedManager {
    static id sharedManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

@end
