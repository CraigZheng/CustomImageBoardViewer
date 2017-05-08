//
//  czzPopularThreadsManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzPopularThreadsManager.h"

#import "czzThreadSuggestion.h"
#import "czzURLDownloader.h"
#import "czzSettingsCentre.h"
#import "UIApplication+Util.h"

@interface czzPopularThreadsManager() <czzURLDownloaderProtocol>
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSArray<czzThreadSuggestion*> *> *> *suggestionsArray;
@property (nonatomic, strong) czzURLDownloader *popularThreadsDownloader;
@end

@implementation czzPopularThreadsManager

- (instancetype)init {
    self = [super init];
    if (self) {
        // Load initial data.
        NSData *localCacheJsonData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"popular_threads" ofType:@"json"]];
        [self parseJsonData:localCacheJsonData];
    }
    return self;
}

- (void)parseJsonData:(NSData*)jsonData {
    if (jsonData) {
        NSArray *dictionaryArray = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:nil];
        NSMutableArray *tempSuggestionsArray = [NSMutableArray new];
        for (NSDictionary *dictionary in dictionaryArray) {
            @try {
                if ([dictionary[@"array"] isKindOfClass:[NSArray class]]) {
                    NSMutableArray *sectionSuggestions = [NSMutableArray new];
                    for (NSDictionary *jsonDict in dictionary[@"array"]) {
                        czzThreadSuggestion *suggestion = [[czzThreadSuggestion alloc] initWithDictionary:jsonDict];
                        [sectionSuggestions addObject:suggestion];
                    }
                    NSDictionary *suggestionDict = @{dictionary[@"section"] ?: @"" : sectionSuggestions};
                    [tempSuggestionsArray addObject:suggestionDict];
                }
            } @catch (NSException *exception) {
                DLog(@"%@", exception);
            }
        }
        if (tempSuggestionsArray.count) {
            [self.suggestionsArray removeAllObjects];
            [self.suggestionsArray addObjectsFromArray:tempSuggestionsArray];
        }
    }
}

- (void)refreshPopularThreads {
    NSString *targetURLString = [[settingCentre popular_threads_link] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [UIApplication bundleVersion]]];
    self.popularThreadsDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLString]
                                                                       delegate:self
                                                                       startNow:YES];
}

#pragma mark - czzURLDownloaderDelegate

- (void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    if (successed && downloadedData) {
        [self parseJsonData:downloadedData];
    }
}

#pragma mark - Getters

- (NSMutableArray<NSDictionary<NSString *,NSArray<czzThreadSuggestion *> *> *> *)suggestionsArray {
    if (!_suggestionsArray) {
        _suggestionsArray = [NSMutableArray new];
    }
    return _suggestionsArray;
}

- (NSArray<NSDictionary<NSString *,NSArray<czzThreadSuggestion *> *> *> *)suggestions {
    return [self.suggestionsArray copy];
}

@end
