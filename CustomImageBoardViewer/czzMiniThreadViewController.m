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
#import "UIBarButtonItem+CIVLayout.h"

@interface czzMiniThreadViewController () <UITableViewDataSource, UITableViewDelegate, czzMenuEnabledTableViewCellProtocol>
@property (nonatomic, assign) NSInteger parentID;
@property (nonatomic, assign) CGSize rowSize;
@property (weak, nonatomic) UIToolbar *miniThreadViewToolBar;
@end

@implementation czzMiniThreadViewController
@synthesize threadTableView;
@synthesize rowSize;
@synthesize parentID;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
    return self;
}

- (void)loadView {
    UIView *rootView = [[UIView alloc] init];
    rootView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.view = rootView;

    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.backgroundColor = [UIColor clearColor];
    [backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBackgroundView:)]];
    [rootView addSubview:backgroundView];

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    [rootView addSubview:tableView];
    self.threadTableView = tableView;
    NSLayoutConstraint *tableHeight = [tableView.heightAnchor constraintEqualToConstant:80];
    self.threadTableViewHeight = tableHeight;

    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [rootView addSubview:toolbar];
    self.miniThreadViewToolBar = toolbar;

    UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
    NSLayoutConstraint *toolbarTop = [toolbar.topAnchor constraintEqualToAnchor:tableView.bottomAnchor];
    toolbarTop.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [backgroundView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [backgroundView.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor],
        [backgroundView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [backgroundView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],

        [tableView.centerYAnchor constraintEqualToAnchor:rootView.centerYAnchor],
        [tableView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        tableHeight,

        toolbarTop,
        [toolbar.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [toolbar.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        [toolbar.heightAnchor constraintEqualToConstant:44],
        [safeArea.bottomAnchor constraintGreaterThanOrEqualToAnchor:toolbar.bottomAnchor]
    ]];
}

#pragma mark - Life cycle.
- (void)viewDidLoad {
    [super viewDidLoad];
    self.miniThreadViewToolBar.barTintColor = [settingCentre barTintColour];
    self.miniThreadViewToolBar.tintColor = [settingCentre tintColour];
    // Avoid iOS 26 zero-width ButtonWrapper conflicts from UIBarButtonSystemItemAction.
    UIImage *actionImage = [UIImage systemImageNamed:@"square.and.arrow.up"] ?: [UIImage imageNamed:@"upload.png"];
    self.miniThreadViewToolBar.items = @[
        [UIBarButtonItem civ_itemWithImage:actionImage target:self action:@selector(openAction:)]
    ];
    
    // Register NIB.
    [threadTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil]
          forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    // Set estimated row height and actual row height.
    threadTableView.rowHeight = UITableViewAutomaticDimension;
    threadTableView.estimatedRowHeight = 44.0;
    threadTableView.delegate = self;
    self.dismissOnTap = NO;
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
        czzThreadViewController *threadViewController = [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
        threadViewController.thread = self.myThread;
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
        cell.parentThread = self.myThread;
        cell.thread = self.myThread;
        cell.nightyMode = [settingCentre userDefNightyMode];
        [cell renderContent];
        cell.delegate = self;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - czzMenuEnabledTableViewCellProtocol
- (void)userTapInImageView:(id)sender {
    czzImageViewerUtil *imageViewer = [czzImageViewerUtil sharedInstance];
    imageViewer.destinationViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        NSURL *url = [[NSURL URLWithString:settingCentre.image_host] URLByAppendingPathComponent:self.myThread.imgSrc];
        if (self.myThread.imgSrc.length) {
            [imageViewer showPhoto:url];
        }
    }];
}

- (void)userTapInQuotedText:(NSString *)text {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate miniThreadViewController:self didSelectedQuotedThread:text];
    }];
}

#pragma mark - rotation event
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [threadTableView reloadData];
}

+ (instancetype)new {
    return [[self alloc] init];
}
@end
