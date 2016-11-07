//
//  czzFavouriteManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 21/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzFavouriteManagerViewController.h"
#import "czzThread.h"
#import "czzAppDelegate.h"
#import "czzThreadViewController.h"
#import "czzHomeViewController.h"
#import "czzTextViewHeightCalculator.h"
#import "czzSettingsCentre.h"
#import "czzFavouriteManager.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadTableViewCommandCellTableViewCell.h"
#import "czzHistoryManager.h"
#import "czzWatchListManager.h"
#import "czzBannerNotificationUtil.h"
#import "czzThreadViewManager.h"
#import "czzThreadTableView.h"
#import "czzMenuEnabledTableViewCell.h"


NSInteger const bookmarkIndex = 0;
NSInteger const watchIndex = 1;
NSInteger const historyIndex = 2;

static NSInteger const browserHistoryIndex = 0;
static NSInteger const postsHistoryIndex = 1;
static NSInteger const respondsHistoryIndex = 2;

@interface czzFavouriteManagerViewController ()
@property (nonatomic, strong) NSIndexPath *selectedIndex;
@property (nonatomic, strong) NSMutableSet *internalThreads;
@property (nonatomic, strong) czzThread *selectedThread;
@property (weak, nonatomic) id selectedManager;
@property (nonatomic, strong) NSArray *updatedThreads;

@end

@implementation czzFavouriteManagerViewController
@synthesize title;
@synthesize internalThreads;
@synthesize selectedIndex;
@synthesize threads;
@synthesize titleSegmentedControl;
@synthesize selectedThread;
@synthesize selectedManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // Launch to index
    self.titleSegmentedControl.selectedSegmentIndex = self.launchToIndex;
    [self copyDataFromManager];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (title) {
        self.title = title;
    }
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [historyManager saveCurrentState];
    [favouriteManager saveCurrentState];
}

- (void)dealloc {
    // During dealloc stage, if the selected list is still watchlist, clear the updatedThread in watchlist manager.
    // We assume user read all of the updated threads.
    if (self.titleSegmentedControl.selectedSegmentIndex == watchIndex) {
        WatchListManager.updatedThreads = nil;
    }
}

#pragma UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return threads.count;
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [threads objectAtIndex:indexPath.row];

    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        @try {
            cell.shouldAllowClickOnImage= NO;
            cell.parentThread = thread;
            cell.thread = thread;
            cell.nightyMode = [settingCentre userDefNightyMode];
            [cell renderContent]; // Render content must be done manually.
        } @catch (NSException *exception) {
            DLog(@"%@", exception)
            [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Exception"
                                                                                                action:@"Exception"
                                                                                                 label:[exception description]
                                                                                                 value:@1] build]];
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        selectedThread = [threads objectAtIndex:selectedIndex.row];
        czzThreadViewController *threadViewController = [czzThreadViewController new];
        threadViewController.thread = selectedThread;
        [NavigationManager pushViewController:threadViewController animated:YES];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        czzThread* threadToDelete = [threads objectAtIndex:indexPath.row];
        if (titleSegmentedControl.selectedSegmentIndex == bookmarkIndex) {
            [favouriteManager removeFavourite:threadToDelete];
        } else if (titleSegmentedControl.selectedSegmentIndex == historyIndex) {
            [historyManager removeThread:threadToDelete];
        } else if (titleSegmentedControl.selectedSegmentIndex == watchIndex) {
            [WatchListManager removeFromWatchList:threadToDelete];
        }
        
        [self copyDataFromManager];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

#pragma mark - UI actions

- (IBAction)editAction:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

- (IBAction)titleSegmentedControlAction:(id)sender {
    [self copyDataFromManager];
    
}

- (void)historyTypeSegmentedControlAction:(id)sender {
    [self copyDataFromManager];
    
}

-(void)copyDataFromManager {
    if (titleSegmentedControl.selectedSegmentIndex == bookmarkIndex) {
        threads = [favouriteManager favouriteThreads].objectEnumerator.allObjects.mutableCopy;
        selectedManager = favouriteManager;
    } else if (titleSegmentedControl.selectedSegmentIndex == historyIndex) {
        // Type of history: broswer, posts, responds.
        if (self.historyTypeSegmentedControl.selectedSegmentIndex == browserHistoryIndex) {
            threads = [historyManager browserHistory];
        } else if (self.historyTypeSegmentedControl.selectedSegmentIndex == postsHistoryIndex) {
            threads = historyManager.postedThreads;
        } else {
            threads = historyManager.respondedThreads;
        }
        selectedManager = historyManager;
        threads = [NSMutableOrderedSet orderedSetWithArray:[[threads reverseObjectEnumerator] allObjects]]; //hisotry are recorded backward
    } else if (titleSegmentedControl.selectedSegmentIndex == watchIndex) {
        threads = [czzWatchListManager sharedManager].watchedThreads.reverseObjectEnumerator.allObjects.mutableCopy;
        selectedManager = WatchListManager;
        // Updated threads have been viewed.
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        if (WatchListManager.updatedThreads.count) {
            [czzBannerNotificationUtil displayMessage:@"已置顶有更新的串"
                                             position:BannerNotificationPositionTop];
        }
    }
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO]; // Scroll to top.
    // If the currently selected title segmented control is history, enable the selection for history type segmented control.
    self.historyTypeSegmentedControl.enabled = self.titleSegmentedControl.selectedSegmentIndex == historyIndex;
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"FavouriteManager" bundle:nil] instantiateViewControllerWithIdentifier:@"favourite_manager_view_controller"];
}

+(UIViewController *)newInNavigationController {
    return [[UIStoryboard storyboardWithName:@"FavouriteManager" bundle:nil] instantiateInitialViewController];
}
@end
