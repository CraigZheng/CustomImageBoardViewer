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
#import "czzSettingsCentre.h"

@import GoogleMobileAds;

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
    return self.popularThreadsManager.suggestions.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    NSDictionary *dictionary = self.popularThreadsManager.suggestions[section - 1];
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
    if (section == 0) {
        return @"广告";
    }
    NSMutableString *title = [NSMutableString new];
    for (NSString *key in self.popularThreadsManager.suggestions[section - 1].allKeys) {
        [title appendString:key];
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *advertisementCell = [tableView dequeueReusableCellWithIdentifier:@"ad_cell_identifier"
                                                                             forIndexPath:indexPath];
        for (UIView *subView in advertisementCell.contentView.subviews) {
            if ([subView isKindOfClass:[GADBannerView class]]) {
                GADBannerView *bannerView = (GADBannerView *)subView;
#ifdef DEBUG
                bannerView.adUnitID = @"ca-app-pub-3940256099942544/6300978111";
#else
                bannerView.adUnitID = @"ca-app-pub-2081665256237089~1718587650";
#endif
                // Set the rootViewController for this banner view to be the czzForumsTableViewController - same as before.
                czzNavigationController *navigationController = UIApplication.rootViewController;
                if ([navigationController isKindOfClass:czzNavigationController.class]) {
                    bannerView.rootViewController = [(UINavigationController*)navigationController.leftViewController viewControllers].firstObject;
                }
                GADRequest *request = [GADRequest request];
                request.testDevices = @[ kGADSimulatorID ];
                [bannerView loadRequest:request];
            }
        }
        return advertisementCell;
    }
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
    if (indexPath.section == 0) {
        return;
    }
    czzThreadSuggestion *suggestion = [self threadSuggestionForIndexPath:indexPath];
    if (suggestion.url) {
        [[UIApplication rootViewController] dismissViewControllerAnimated:YES completion:^{
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
    if (indexPath.section == 0) {
        return nil;
    }
    @try {
        NSMutableArray *suggestionsArray = [NSMutableArray new];
        for (NSString *key in self.popularThreadsManager.suggestions[indexPath.section - 1].allKeys) {
            [suggestionsArray addObjectsFromArray:[self.popularThreadsManager.suggestions[indexPath.section - 1] objectForKey:key]];
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
