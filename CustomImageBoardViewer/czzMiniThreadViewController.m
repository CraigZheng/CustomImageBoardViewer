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
#import "czzMenuEnabledTableViewCell.h"

@interface czzMiniThreadViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) czzThread *myThread;
@end

@implementation czzMiniThreadViewController
@synthesize threadID;
@synthesize myThread;
@synthesize threadTableView;

static NSString *cellIdentifier = @"thread_cell_identifier";
static NSString *emptyCellIdenfiier = @"empty_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UINib *cellNib = [UINib nibWithNibName:@"czzThreadViewTableViewCell" bundle:nil];
    [threadTableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSString *target = [NSString stringWithFormat:@"http://h.acfun.tv/t/%ld.json", (long)threadID];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:target]]  queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError) {
            NSDictionary *rawJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            czzThread *resultThread = [[czzThread alloc] initWithJSONDictionary:[rawJson objectForKey:@"threads"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (resultThread)
                    [self setMyThread:resultThread];
            });
        }
    }];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell) {
//        cell.shouldHighlight = NO;
//        cell.parentThread = myThread;
//        cell.myThread = myThread;
        
    }
    return cell;
}
#pragma mark - uitableview delegate
@end
