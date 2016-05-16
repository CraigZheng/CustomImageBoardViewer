//
//  czzMiniThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzMiniThreadViewController.h"

#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzImageViewerUtil.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "czzThreadViewManager.h"
#import "czzFadeInOutModalAnimator.h"

@interface czzMiniThreadViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) NSInteger parentID;
@property (nonatomic, assign) CGSize rowSize;
@property (weak, nonatomic) IBOutlet UIToolbar *miniThreadViewToolBar;
@end

@implementation czzMiniThreadViewController
@synthesize threadTableView;
@synthesize rowSize;
@synthesize parentID;

#pragma mark - Life cycle.
- (void)viewDidLoad {
    [super viewDidLoad];
    self.miniThreadViewToolBar.barTintColor = [settingCentre barTintColour];
    self.miniThreadViewToolBar.tintColor = [settingCentre tintColour];
    
    // Register NIB.
    [threadTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil]
          forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    // Set estimated row height and actual row height.
    threadTableView.rowHeight = UITableViewAutomaticDimension;
    threadTableView.estimatedRowHeight = 44.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.threadTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.threadTableViewHeight.constant = self.threadTableView.contentSize.height;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [AppDelegate.window hideToastActivity];
}

#pragma mark - UI actions.
- (IBAction)openAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.myThread) {
        czzThreadViewManager *threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:self.myThread andForum:nil];
        czzThreadViewController *threadViewController = [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
        threadViewController.threadViewManager = threadViewManager;
        [NavigationManager pushViewController:threadViewController animated:YES];
    }
}

- (IBAction)tapOnBackgroundView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.myThread ? 1 : 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = THREAD_VIEW_CELL_IDENTIFIER;
    
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell) {
        cell.shouldHighlight = NO;
        cell.parentThread = self.myThread;
        cell.thread = self.myThread;
        cell.nightyMode = [settingCentre userDefNightyMode];
        [cell renderContent];
    }
    return cell;
}

#pragma mark - rotation event
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [threadTableView reloadData];
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"MiniThreadView" bundle:nil] instantiateViewControllerWithIdentifier:@"mini_thread_view_controller"];
}
@end
