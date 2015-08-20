//
//  czzForumManager.m
//  CustomImageBoardViewer
//
//  Created by Craig on 19/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzForumManager.h"
#import "czzURLDownloader.h"
#import "czzForumGroup.h"
#import "czzSettingsCentre.h"

@interface czzForumManager() <czzURLDownloaderProtocol>
@property czzURLDownloader *forumDownloader;
@property (copy) void (^completionHandler) (BOOL, NSError*);
@end

@implementation czzForumManager

- (void)updateForums:(void (^)(BOOL, NSError *))completionHandler {
    if (self.forumDownloader)
        [self.forumDownloader stop];
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    NSString *forumString = [[settingCentre forum_list_url] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [NSString stringWithFormat:@"%@-%@", bundleIdentifier, versionString]]];
    NSLog(@"Forum config URL: %@", forumString);
    self.forumDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];

    self.completionHandler = completionHandler;
}

#pragma mark - Getters
- (NSArray *)forumGroups {
    if (!_forumGroups) {
        _forumGroups = [NSMutableArray new];
    }
    return _forumGroups;
}

- (NSArray *)forums {
    NSMutableArray *forums = [NSMutableArray new];
    
    for (czzForumGroup *forumGroup in self.forumGroups) {
        [forums addObjectsFromArray:forumGroup.forums];
    }
    
    return forums;
}

#pragma mark - czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData {
    @try {
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:xmlData options:NSJSONReadingMutableContainers error:nil];
        if (jsonArray.count) {
            for (NSDictionary *dictionary in jsonArray) {
                [self.forumGroups addObject:[czzForumGroup initWithDictionary:dictionary]];
            }
        }
    }
    @catch (NSException *exception) {
        // If exception, not successed.
        DLog(@"%@", exception);
        successed = NO;
    }

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
