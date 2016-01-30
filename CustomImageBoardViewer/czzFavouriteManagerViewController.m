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
#import "czzThreadViewManager.h"
#import "czzMenuEnabledTableViewCell.h"


NSInteger const bookmarkIndex = 0;
NSInteger const watchIndex = 1;
NSInteger const historyIndex = 2;

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
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self copyDataFromManager];
    if (title) {
        self.title = title;
    }
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
    [self.tableView reloadData];
    
    self.navigationController.toolbarHidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [historyManager saveCurrentState];
    [favouriteManager saveCurrentState];
    
    self.navigationController.toolbarHidden = NO;
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
        cell.shouldAllowClickOnImage= NO;
        cell.shouldHighlight = NO;
        cell.parentThread = thread;
        cell.thread = thread;
        [cell renderContent]; // Render content must be done manually.
    }
    // TODO: need to create a standalone watchlist manager, or improve this one.
    // If I am seeing the list from watchlist
    if (selectedManager == [czzWatchListManager sharedManager]) {
        for (czzThread *updatedThread in [[czzWatchListManager sharedManager] updatedThreads]) {
            if (updatedThread.ID == thread.ID) {
                //TODO: highligh
            }
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        selectedThread = [threads objectAtIndex:selectedIndex.row];
        czzThreadViewManager *threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:selectedThread andForum:nil];
        czzThreadViewController *threadViewController = [czzThreadViewController new];
        threadViewController.threadViewManager = threadViewManager;
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
            [[czzWatchListManager sharedManager] removeFromWatchList:threadToDelete];
        }
        
        [self copyDataFromManager];
        [tableView reloadData];
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
    [self.tableView reloadData];
}

-(void)copyDataFromManager {
    if (titleSegmentedControl.selectedSegmentIndex == bookmarkIndex) {
        threads = [favouriteManager favouriteThreads];
        selectedManager = favouriteManager;
    } else if (titleSegmentedControl.selectedSegmentIndex == historyIndex) {
        threads = [historyManager browserHistory];
        selectedManager = historyManager;
        threads = [NSMutableOrderedSet orderedSetWithArray:[[threads reverseObjectEnumerator] allObjects]]; //hisotry are recorded backward
    } else if (titleSegmentedControl.selectedSegmentIndex == watchIndex) {
        threads = [czzWatchListManager sharedManager].watchedThreads;
        selectedManager = [czzWatchListManager sharedManager];
        //Update watched threads
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
//        [[czzWatchListManager sharedManager] refreshWatchedThreads:^(NSArray *updatedThreads) {
//            self.updatedThreads = updatedThreads;
//            [self.tableView reloadData];
//        }];
    }
}

#pragma mark - rotation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.tableView reloadData];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"FavouriteManager" bundle:nil] instantiateViewControllerWithIdentifier:@"favourite_manager_view_controller"];
}

+(UIViewController *)newInNavigationController {
    return [[UIStoryboard storyboardWithName:@"FavouriteManager" bundle:nil] instantiateInitialViewController];
}
@end
