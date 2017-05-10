//
//  czzForumsTableViewThreadSuggestionsManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzForumsTableViewThreadSuggestionsManager.h"

#import "czzPopularThreadsManager.h"
#import "czzThreadSuggestion.h"
#import "czzURLHandler.h"
#import "czzNavigationManager.h"
#import "SlideNavigationController.h"
#import "czzSettingsCentre.h"

@interface czzForumsTableViewThreadSuggestionsManager()
@end

@implementation czzForumsTableViewThreadSuggestionsManager

- (instancetype)initWithPopularThreadsManager:(czzPopularThreadsManager *)manager {
    self = [self init];
    if (self) {
        _popularThreadsManager = manager;
    }
    return self;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.popularThreadsManager.suggestions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dictionary = self.popularThreadsManager.suggestions[section];
    NSInteger count = 0;
    for (NSString *key in dictionary.allKeys) {
        if ([dictionary[key] isKindOfClass:[NSArray class]]) {
            count += [dictionary[key] count];
        }
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSMutableString *title = [NSMutableString new];
    for (NSString *key in self.popularThreadsManager.suggestions[section].allKeys) {
        [title appendString:key];
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *suggestionCell = [tableView dequeueReusableCellWithIdentifier:@"thread_cell_identifier"
                                                                      forIndexPath:indexPath];
    if (suggestionCell) {
        czzThreadSuggestion *suggestion = [self threadSuggestionForIndexPath:indexPath];
        if (suggestion) {
            suggestionCell.textLabel.text = suggestion.title;
            suggestionCell.detailTextLabel.text = suggestion.content;
        }
    }
    suggestionCell.textLabel.textColor = [settingCentre contentTextColour];
    suggestionCell.contentView.backgroundColor = [settingCentre viewBackgroundColour];
    return suggestionCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    czzThreadSuggestion *suggestion = [self threadSuggestionForIndexPath:indexPath];
    if (suggestion.url) {
        [[SlideNavigationController sharedInstance] closeMenuWithCompletion:^{
            [czzURLHandler handleURL:suggestion.url];
        }];
    }
    // Analytics.
    id<GAITracker> defaultTracker = [[GAI sharedInstance] defaultTracker];
    [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"PopularThread"
                                                                 action:@"Selected"
                                                                  label:[NSString stringWithFormat:@"%@ - %@", suggestion.title, suggestion.url]
                                                                  value:@1] build]];
    
}

#pragma mark - Util methods.

- (czzThreadSuggestion *)threadSuggestionForIndexPath:(NSIndexPath *)indexPath {
    @try {
        NSMutableArray *suggestionsArray = [NSMutableArray new];
        for (NSString *key in self.popularThreadsManager.suggestions[indexPath.section].allKeys) {
            [suggestionsArray addObjectsFromArray:[self.popularThreadsManager.suggestions[indexPath.section] objectForKey:key]];
        }
        czzThreadSuggestion *suggestion = suggestionsArray[indexPath.row];
        return suggestion;
    } @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return nil;
}

#pragma mark - Getters

- (czzPopularThreadsManager *)popularThreadsManager {
    // Should never be nil.
    assert(_popularThreadsManager != nil);
    return _popularThreadsManager;
}

@end
