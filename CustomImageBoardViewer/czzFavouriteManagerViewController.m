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
#import "czzBannerNotificationUtil.h"
#import "czzThreadViewManager.h"
#import "czzThreadTableView.h"
#import "czzMenuEnabledTableViewCell.h"


NSInteger const bookmarkIndex = 0;
NSInteger const historyIndex = 1;

static NSInteger const browserHistoryIndex = 0;
static NSInteger const postsHistoryIndex = 1;
static NSInteger const respondsHistoryIndex = 2;

@interface czzFavouriteManagerViewController () <UIStateRestoring>
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

- (void)loadView {
    UIView *rootView = [[UIView alloc] init];
    rootView.backgroundColor = [UIColor whiteColor];
    self.view = rootView;

    czzThreadTableView *threadTableView = [[czzThreadTableView alloc] initWithFrame:CGRectZero];
    threadTableView.translatesAutoresizingMaskIntoConstraints = NO;
    threadTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    threadTableView.dataSource = self;
    threadTableView.delegate = self;
    [rootView addSubview:threadTableView];
    self.tableView = threadTableView;

    [NSLayoutConstraint activateConstraints:@[
        [threadTableView.topAnchor constraintEqualToAnchor:rootView.topAnchor],
        [threadTableView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [threadTableView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        [threadTableView.bottomAnchor constraintEqualToAnchor:rootView.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UISegmentedControl *titleControl = [[UISegmentedControl alloc] initWithItems:@[@"收藏", @"历史"]];
    titleControl.selectedSegmentIndex = 0;
    [titleControl addTarget:self action:@selector(titleSegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = titleControl;
    self.titleSegmentedControl = titleControl;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"trash.png"] style:UIBarButtonItemStylePlain target:self action:@selector(editAction:)];

    UISegmentedControl *historyControl = [[UISegmentedControl alloc] initWithItems:@[@"浏览", @"发送", @"回复"]];
    historyControl.selectedSegmentIndex = 0;
    [historyControl addTarget:self action:@selector(historyTypeSegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    self.historyTypeSegmentedControl = historyControl;
    self.toolbarItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithCustomView:historyControl],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
    ];

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
        // The table can still hold an index that the backing store no longer has,
        // e.g. when a second delete arrives before the first reload lands.
        if (indexPath.row >= threads.count) {
            [self copyDataFromManager];
            return;
        }
        czzThread* threadToDelete = [threads objectAtIndex:indexPath.row];
        if (titleSegmentedControl.selectedSegmentIndex == bookmarkIndex) {
            [favouriteManager removeFavourite:threadToDelete];
        } else if (titleSegmentedControl.selectedSegmentIndex == historyIndex) {
            // Only remove the entry from the list currently on screen; the same
            // thread may also be recorded under the other history tabs.
            [historyManager removeThread:threadToDelete fromList:[self selectedHistoryListType]];
        }

        [self copyDataFromManager];
    }
}

- (czzHistoryListType)selectedHistoryListType {
    switch (self.historyTypeSegmentedControl.selectedSegmentIndex) {
        case postsHistoryIndex:
            return czzHistoryListTypePosted;
        case respondsHistoryIndex:
            return czzHistoryListTypeResponded;
        case browserHistoryIndex:
        default:
            return czzHistoryListTypeBrowser;
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
        NSMutableOrderedSet *historyThreads;
        if (self.historyTypeSegmentedControl.selectedSegmentIndex == browserHistoryIndex) {
            historyThreads = [historyManager browserHistory];
        } else if (self.historyTypeSegmentedControl.selectedSegmentIndex == postsHistoryIndex) {
            historyThreads = historyManager.postedThreads;
        } else {
            historyThreads = historyManager.respondedThreads;
        }
        selectedManager = historyManager;
        // Copy before reversing: assigning the manager's own set here would alias
        // it, so deleting a row would mutate the list mid-enumeration.
        threads = [NSMutableOrderedSet orderedSetWithArray:[[historyThreads reverseObjectEnumerator] allObjects]]; //hisotry are recorded backward
    }
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO]; // Scroll to top.
    // If the currently selected title segmented control is history, enable the selection for history type segmented control.
    self.historyTypeSegmentedControl.enabled = self.titleSegmentedControl.selectedSegmentIndex == historyIndex;
}

#pragma mark - UIStateRestoring

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeInteger:self.titleSegmentedControl.selectedSegmentIndex forKey:@"titleSegmentedControl"];
    [coder encodeInteger:self.historyTypeSegmentedControl.selectedSegmentIndex forKey:@"historyTypeSegmentedControl"];
    [coder encodeObject:[NSValue valueWithCGPoint:self.tableView.contentOffset] forKey:@"TableViewContentOffset"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    self.titleSegmentedControl.selectedSegmentIndex = [coder decodeIntegerForKey:@"titleSegmentedControl"];
    self.historyTypeSegmentedControl.selectedSegmentIndex = [coder decodeIntegerForKey:@"historyTypeSegmentedControl"];
    NSValue *contentOffsetValue;
    if ([(contentOffsetValue = [coder decodeObjectForKey:@"TableViewContentOffset"]) isKindOfClass:[NSValue class]]) {
        [self.tableView setContentOffset:contentOffsetValue.CGPointValue];
    }
    [super decodeRestorableStateWithCoder:coder];
}

- (void)applicationFinishedRestoringState {
    [self copyDataFromManager];
}

+(instancetype)new {
    return [[self alloc] init];
}

+(UIViewController *)newInNavigationController {
    return [self new];
}
@end
