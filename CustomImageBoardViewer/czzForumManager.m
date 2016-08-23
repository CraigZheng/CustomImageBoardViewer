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

static NSString * kCustomForumsRawStringsKey = @"kCustomForumsRawStringsKey";

@interface czzForumManager() <czzURLDownloaderProtocol>
@property czzURLDownloader *forumDownloader;
@property (copy) void (^completionHandler) (BOOL, NSError*);
@property (strong, nonatomic) NSMutableArray * customForumRawStrings;
@end

@implementation czzForumManager

- (void)updateForums:(void (^)(BOOL, NSError *))completionHandler {
    if (self.forumDownloader.isDownloading)
        [self.forumDownloader stop];

    NSString *forumString = [[settingCentre forum_list_url] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [UIApplication bundleVersion]]];
    NSLog(@"Forum config URL: %@", forumString);
    self.forumDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];

    self.completionHandler = completionHandler;
}

- (void)addCustomForumWithName:(NSString *)forumName id:(NSInteger)forumID {
    if (forumName.length) {
        // Reset custom forums.
        self.customForums = nil;
        [self.customForumRawStrings addObject:@{forumName : @(forumID)}];
        [[NSUserDefaults standardUserDefaults] setObject:self.customForumRawStrings
                                                  forKey:kCustomForumsRawStringsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
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

- (NSMutableArray *)customForumRawStrings {
    if (!_customForumRawStrings) {
        _customForumRawStrings = [NSMutableArray new];
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:kCustomForumsRawStringsKey] isKindOfClass:[NSArray class]]) {
            _customForumRawStrings = [[[NSUserDefaults standardUserDefaults] objectForKey:kCustomForumsRawStringsKey] mutableCopy];
        }
    }
    return _customForumRawStrings;
}

- (NSMutableArray *)customForums {
    if (!_customForums) {
        // TODO: check NSUserDefaults for previously saved forums strings.
        _customForums = [NSMutableArray new];
        for (NSDictionary *dictionary in self.customForumRawStrings) {
            if ([dictionary isKindOfClass:[NSDictionary class]]) {
                NSString *forumName = dictionary.allKeys.firstObject;
                NSNumber *forumID = dictionary.allValues.firstObject;
                if (forumName.length && forumID) {
                    // When forumName and forumID are not nil, construct a new forum object and add to self.customForums.
                    czzForum *forum = [czzForum new];
                    forum.name = forum.screenName = forumName;
                    forum.forumID = [forumID integerValue];
                    [_customForums addObject:forum];
                }
            }
        }
    }
    return _customForums;
}

#pragma mark - czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData {
    @try {
        if (successed) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:xmlData options:NSJSONReadingMutableContainers error:nil];
            if (jsonArray.count) {
                [self.forumGroups removeAllObjects];
                for (NSDictionary *dictionary in jsonArray) {
                    [self.forumGroups addObject:[czzForumGroup initWithDictionary:dictionary]];
                }
            }
        }
    }
    @catch (NSException *exception) {
        // If exception, not successed.
        DDLogDebug(@"%@", exception);
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
