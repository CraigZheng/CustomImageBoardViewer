//
//  czzMiniThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define THREAD_VIEW_CELL_NIB @"czzThreadViewTableViewCell"

#import "czzMiniThreadViewController.h"
#import "czzThread.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzImageViewerUtil.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzTextViewHeightCalculator.h"

@interface czzMiniThreadViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) czzThread *myThread;
@property CGSize rowSize;
@end

@implementation czzMiniThreadViewController
@synthesize threadID;
@synthesize myThread;
@synthesize threadTableView;
@synthesize delegate;
@synthesize rowSize;
@synthesize miniThreadNaBarItem;
@synthesize miniThreadNavBar;

static NSString *cellIdentifier = @"thread_cell_identifier";
static NSString *emptyCellIdenfiier = @"empty_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UINib *cellNib = [UINib nibWithNibName:@"czzThreadViewTableViewCell" bundle:nil];
    [threadTableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
}

-(void)setThreadID:(NSInteger)tID {
    threadID = tID;
    //start downloading content for thread id
    [[czzAppDelegate sharedAppDelegate].window makeToastActivity];
    NSString *target = [NSString stringWithFormat:@"http://h.acfun.tv/t/%ld.json", (long)threadID];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:target]]  queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError) {
            NSDictionary *rawJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            czzThread *resultThread = [[czzThread alloc] initWithJSONDictionary:[rawJson objectForKey:@"threads"]];
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
        }
    }];
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
    preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForContent:myThread.content inView:self.view hasImage:myThread.thImgSrc.length > 0];
    preferHeight = MAX(tableView.rowHeight, preferHeight);
    rowSize = CGSizeMake(self.view.frame.size.width, preferHeight);

    return preferHeight;
}

#pragma mark - uitableview delegate
- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - rotation event
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [threadTableView reloadData];
}
@end
