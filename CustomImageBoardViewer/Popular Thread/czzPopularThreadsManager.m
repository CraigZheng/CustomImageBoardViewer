//
//  czzPopularThreadsManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzPopularThreadsManager.h"

#import "czzThreadSuggestion.h"

@interface czzPopularThreadsManager()
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSArray<czzThreadSuggestion*> *> *> *suggestionsArray;
@end

@implementation czzPopularThreadsManager

- (instancetype)init {
    self = [super init];
    if (self) {
        // Load initial data.
        NSData *localCacheJsonData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"popular_threads" ofType:@"json"]];
        NSArray *dictionaryArray = [NSJSONSerialization JSONObjectWithData:localCacheJsonData options:NSJSONReadingMutableContainers error:nil];
        for (NSDictionary *dictionary in dictionaryArray) {
            @try {
                if ([dictionary[@"array"] isKindOfClass:[NSArray class]]) {
                    NSMutableArray *sectionSuggestions = [NSMutableArray new];
                    for (NSDictionary *jsonDict in dictionary[@"array"]) {
                        czzThreadSuggestion *suggestion = [[czzThreadSuggestion alloc] initWithDictionary:jsonDict];
                        [sectionSuggestions addObject:suggestion];
                    }
                    NSDictionary *suggestionDict = @{dictionary[@"section"] ?: @"" : sectionSuggestions};
                    [self.suggestionsArray addObject:suggestionDict];
                }
            } @catch (NSException *exception) {
                DLog(@"%@", exception);
            }
        }
    }
    return self;
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
