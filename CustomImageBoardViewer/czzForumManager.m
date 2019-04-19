//
//  czzForumManager.m
//  CustomImageBoardViewer
//
//  Created by Craig on 19/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzForumManager.h"
#import "czzURLDownloader.h"
#import "czzForum.h"
#import "czzForumGroup.h"
#import "czzSettingsCentre.h"

static NSString * kCustomForumsRawStringsKey = @"kCustomForumsRawStringsKey";
static NSString * kDefaultForumJsonFileName = @"default_forums.json";

@interface czzForumManager() <czzURLDownloaderProtocol>

@property czzURLDownloader *forumDownloader;
@property (nonatomic, strong, readwrite) NSMutableArray<czzForumGroup*> *forumGroups;
@property (copy) void (^completionHandler) (BOOL, NSError*);
@property (strong, nonatomic) NSMutableArray<NSDictionary<NSString*, NSNumber*>*> * customForumRawStrings;
@property (strong, nonatomic) NSData *forumsJSONData;
@property (strong, nonatomic) NSData *aDaoForumJSONData;
@property (strong, nonatomic) NSURL *getForumURL;
@end

@implementation czzForumManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _getForumURL = [[NSURL alloc] initWithString:@"https://adnmb.com/Api/getForumList"];
        NSString *jsonString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"default_forums"
                                                                                                  ofType:@"json"]
                                                         encoding:NSUTF8StringEncoding
                                                            error:nil];
        if (jsonString.length) {
            @try {
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                if (jsonData) {
                  self.forumsJSONData = jsonData;
                  [self resetForums];
                }
            } @catch (NSException *exception) {
                DLog(@"%@", exception);
            }
        }
    }
    return self;
}

- (void)updateForums:(void (^)(BOOL, NSError *))completionHandler {
    if (self.forumDownloader.isDownloading)
        [self.forumDownloader stop];

    NSString *forumString = [[settingCentre forum_list_url] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [UIApplication bundleVersion]]];
    NSLog(@"Forum config URL: %@", forumString);
    self.forumDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];
    __weak typeof(self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithRequest:[[NSURLRequest alloc] initWithURL:self.getForumURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            weakSelf.aDaoForumJSONData = data;
            [weakSelf resetForums];
            if (weakSelf.completionHandler) {
                weakSelf.completionHandler(YES, nil);
            }
        }
    }] resume];
    self.completionHandler = completionHandler;
}

- (void)addCustomForumWithName:(NSString *)forumName forumID:(NSInteger)forumID {
    if (forumName.length) {
        // Reset custom forums.
        self.customForums = nil;
        [self.customForumRawStrings addObject:@{forumName : @(forumID)}];
        [[NSUserDefaults standardUserDefaults] setObject:self.customForumRawStrings
                                                  forKey:kCustomForumsRawStringsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // Notify others that a custom forum is added.
        [[NSNotificationCenter defaultCenter] postNotificationName:kCustomForumDidChangeNotification object:nil];
    }
}

- (void)removeCustomForum:(czzForum *)forum {
    // Reset self.customForums array.
    self.customForums = nil;
    // Loop through all raw strings, remove the ones with the same name and ID.
    for (NSDictionary<NSString*, NSNumber*> *dictionary in self.customForumRawStrings.copy) {
        if ([dictionary.allKeys.firstObject isEqualToString:forum.name] && dictionary.allValues.firstObject.integerValue == forum.forumID) {
            [self.customForumRawStrings removeObject:dictionary];
            [[NSNotificationCenter defaultCenter] postNotificationName:kCustomForumDidChangeNotification object:nil];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.customForumRawStrings
                                              forKey:kCustomForumsRawStringsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetForums {
  self.forumGroups = nil;
  self.forums = nil;
}

#pragma mark - Getters
- (NSArray *)forumGroups {
    if (!_forumGroups) {
        _forumGroups = [NSMutableArray new];
        self.forums = nil;
        if (self.forumsJSONData.length) {
            NSArray<NSDictionary<NSString *, NSObject *> *> *jsonArray = [NSJSONSerialization JSONObjectWithData:self.forumsJSONData
                                                                                                         options:NSJSONReadingMutableContainers
                                                                                                           error:nil];
            __block NSArray<NSDictionary<NSString *, NSObject *> *> *forumsGroupDictionaryArray;
            [jsonArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *configurationName = (id)obj[@"configuration_name"];
                NSArray<NSDictionary<NSString *, NSObject *> *> *tempArray = (id)obj[@"forums"];
                switch ([settingCentre userDefActiveHost]) {
                    case SettingsHostAC:
                        if ([configurationName isEqualToString:@"AC"]) {
                            if (self.aDaoForumJSONData.length) {
                                tempArray = [NSJSONSerialization JSONObjectWithData:self.aDaoForumJSONData options:NSJSONReadingMutableLeaves error:nil];
                            }
                            forumsGroupDictionaryArray = tempArray;
                        }
                        break;
                    case SettingsHostBT:
                        if ([configurationName isEqualToString:@"BT"]) {
                            forumsGroupDictionaryArray = tempArray;
                        }
                        break;
                    default:
                        break;
                }
            }];
            [forumsGroupDictionaryArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                czzForumGroup *forumGroups = [czzForumGroup initWithDictionary:obj];
                NSMutableArray<czzForum*> *tempForums = forumGroups.forums.mutableCopy;
                for (czzForum *forum in forumGroups.forums) {
                    if (forum.forumID < 0) {
                        [tempForums removeObject:forum];
                    }
                }
                forumGroups.forums = tempForums;
                if (forumGroups) {
                    [_forumGroups addObject:forumGroups];
                }
            }];
        }
  }
  return _forumGroups;
}

- (NSArray *)forums {
    if (!_forums) {
        NSMutableArray *tempForums = [NSMutableArray new];
        for (czzForumGroup *forumGroup in self.forumGroups) {
            [tempForums addObjectsFromArray:forumGroup.forums];
        }
        _forums = tempForums;
    }
    return _forums;
}

- (NSMutableArray<NSDictionary<NSString *,NSNumber *> *> *)customForumRawStrings {
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
        self.forumsJSONData = xmlData;
        [self resetForums];
      }
    }
  }
  @catch (NSException *exception) {
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
