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
@property (nonatomic) czzThread *myThread;
@property NSInteger parentID;
@property CGSize rowSize;
@end

@implementation czzMiniThreadViewController
@synthesize threadID;
@synthesize myThread;
@synthesize threadTableView;
@synthesize delegate;
@synthesize rowSize;
@synthesize parentID;
@synthesize miniThreadNaBarItem;
@synthesize miniThreadNavBar;
@synthesize barBackgroundView;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //register NIB
    [threadTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    [threadTableView registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    
    //colours
    miniThreadNavBar.barTintColor = [settingCentre barTintColour];
    miniThreadNavBar.tintColor = [settingCentre tintColour];
    [miniThreadNavBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : miniThreadNavBar.tintColor}];
    barBackgroundView.backgroundColor = [settingCentre barTintColour];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
}

-(void)setThreadID:(NSInteger)tID {
    threadID = tID;
    //start downloading content for thread id
    [[czzAppDelegate sharedAppDelegate].window makeToastActivity];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        czzThread *resultThread = [[czzThread alloc] initWithThreadID:threadID];
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL successful = NO;
            [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
            if (resultThread) {
                [self setMyThread:resultThread];
                successful = YES;
                //reset my frame to show the only table view row
            }
            if (delegate && [delegate respondsToSelector:@selector(miniThreadViewFinishedLoading:)])
                [delegate miniThreadViewFinishedLoading:successful];
            miniThreadNaBarItem.title = myThread.title;
            miniThreadNaBarItem.backBarButtonItem.title = self.title;
            
        });
    });
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)setMyThread:(czzThread *)thread {
    myThread = thread;
    [self.threadTableView reloadData];
}

#pragma mark -uitableview datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return myThread ? 1 : 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell) {
        cell.shouldHighlight = NO;
        cell.parentThread = myThread;
        cell.myThread = myThread;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat preferHeight = tableView.rowHeight;
    preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:myThread inView:self.view hasImage:myThread.thImgSrc.length > 0];
    preferHeight = MAX(tableView.rowHeight, preferHeight);
    rowSize = CGSizeMake(self.view.frame.size.width, preferHeight);

    return preferHeight;
}

#pragma mark - uitableview delegate
- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openThreadAction:(id)sender {
    [[czzAppDelegate sharedAppDelegate].window makeToastActivity];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        czzThread *parentThread = [[czzThread alloc] initWithThreadID:myThread.parentID ? myThread.parentID : myThread.ID];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (parentThread) {
                if (delegate && [delegate respondsToSelector:@selector(miniThreadWantsToOpenThread:)])
                    [delegate miniThreadWantsToOpenThread:parentThread];
            } else {
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法打开！"];
            }
            [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
        });
    });
}

#pragma mark - rotation event
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [threadTableView reloadData];
}
@end
