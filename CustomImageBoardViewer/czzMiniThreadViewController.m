//
//  czzMiniThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzMiniThreadViewController.h"
#import "czzThread.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzImageViewerUtil.h"
#import "czzSettingsCentre.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzTextViewHeightCalculator.h"

@interface czzMiniThreadViewController () <UITableViewDataSource, UITableViewDelegate>
@property NSInteger parentID;
@property CGSize rowSize;
@property KLCPopup *popup;
@end

@implementation czzMiniThreadViewController
@synthesize threadTableView;
@synthesize rowSize;
@synthesize parentID;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //register NIB
    [threadTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    [threadTableView registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [AppDelegate.window hideToastActivity];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)show{
    self.popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeFadeIn dismissType:KLCPopupDismissTypeFadeOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:YES];
    [self.threadTableView reloadData];
    [self.popup show];
}

-(void)setMyThread:(czzThread *)thread {
    _myThread = thread;
    [self.threadTableView reloadData];
}

#pragma mark -uitableview datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.myThread ? 1 : 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell) {
        cell.shouldHighlight = NO;
        cell.parentThread = self.myThread;
        cell.myThread = self.myThread;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat preferHeight = tableView.rowHeight;
    preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:self.myThread inView:self.view hasImage:self.myThread.thImgSrc.length > 0];
    preferHeight = MAX(tableView.rowHeight, preferHeight);
    rowSize = CGSizeMake(self.view.frame.size.width, preferHeight);

    self.threadTableViewHeight.constant = preferHeight;
    return preferHeight;
}


#pragma mark - rotation event
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [threadTableView reloadData];
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"MiniThreadView" bundle:nil] instantiateViewControllerWithIdentifier:@"mini_thread_view_controller"];
}
@end
