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
#import "czzThreadViewModelManager.h"

NSInteger const bookmarkIndex = 0;
NSInteger const watchIndex = 1;
NSInteger const historyIndex = 2;

@interface czzFavouriteManagerViewController ()
@property NSIndexPath *selectedIndex;
@property NSMutableSet *internalThreads;
@property czzThread *selectedThread;
@property (weak, nonatomic) id selectedManager;
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
    [self copyDataFromManager];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (title) {
        self.title = title;
    }
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
    [self.tableView reloadData];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    return;
    //not ready
    [historyManager saveCurrentState];
    [favouriteManager saveCurrentState];
}

#pragma UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return threads.count;
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *cell_identifier = [[czzSettingsCentre sharedInstance] userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [threads objectAtIndex:indexPath.row];

    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        cell.shouldAllowClickOnImage= NO;
        cell.shouldHighlight = NO;
        cell.parentThread = thread;
        cell.myThread = thread;
    }
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        selectedThread = [threads objectAtIndex:selectedIndex.row];
        czzThreadViewModelManager *threadViewModelManager = [[czzThreadViewModelManager alloc] initWithParentThread:selectedThread andForum:selectedThread.forum];
        czzThreadViewController *threadViewController = [czzThreadViewController new];
        threadViewController.viewModelManager = threadViewModelManager;
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
        [selectedManager setHorizontalHeights:nil];
        [selectedManager setVerticalHeights:nil];
        
        [self copyDataFromManager];
        [tableView reloadData];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

//-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewAutomaticDimension;
//}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row >= threads.count)
        return tableView.rowHeight;
    
    czzThread *thread = [threads objectAtIndex:indexPath.row];
    NSMutableArray *heightsArray;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        if (![selectedManager horizontalHeights])
            [selectedManager setHorizontalHeights:[NSMutableArray new]];
        heightsArray = [selectedManager horizontalHeights];
    } else
    {
        if (![selectedManager verticalHeights])
            [selectedManager setVerticalHeights:[NSMutableArray new]];
        heightsArray = [selectedManager verticalHeights];
    }
    if (!heightsArray)
        heightsArray = [NSMutableArray new];
    
    CGFloat preferHeight = tableView.rowHeight;
    if (heightsArray.count > indexPath.row + 1){
        preferHeight = [[heightsArray objectAtIndex:indexPath.row] doubleValue];
    } else {
        preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:self.view hasImage:thread.thImgSrc.length > 0];
        preferHeight = MAX(tableView.rowHeight, preferHeight);
        [heightsArray addObject:[NSNumber numberWithDouble:preferHeight]];
    }
    return preferHeight;
}

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
        //clear cached heights, since history manager would change frequently
        [historyManager setHorizontalHeights:nil];
        [historyManager setVerticalHeights:nil];
        selectedManager = historyManager;
        threads = [NSMutableOrderedSet orderedSetWithArray:[[threads reverseObjectEnumerator] allObjects]]; //hisotry are recorded backward
    } else if (titleSegmentedControl.selectedSegmentIndex == watchIndex) {
        threads = [czzWatchListManager sharedManager].watchedThreads;
        selectedManager = [czzWatchListManager sharedManager];
    }
}

#pragma mark - rotation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.tableView reloadData];
}
@end
