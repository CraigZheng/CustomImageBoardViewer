//
//  czzHTMLParserTestTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHTMLParserTestTableViewController.h"
#import "czzHTMLToThreadParser.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "NSString+HTML.h"

@interface czzHTMLParserTestTableViewController ()
@property NSArray *threads;
@end

@implementation czzHTMLParserTestTableViewController
@synthesize threads;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    //DEBUGGING HTML PARSER
    czzHTMLToThreadParser *parser = [[czzHTMLToThreadParser alloc] init];
    NSString *httpAddress = @"http://h.acfun.tv/漫画";
    NSURL *httpURL = [[NSURL alloc] initWithString:[httpAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSData *htmlData = [NSData dataWithContentsOfURL:httpURL];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    [parser parse:htmlString];
    
    
    NSMutableArray *tempArray = [NSMutableArray new];
    for (czzThread *thread in parser.parsedThreads) {
        if (thread.isParent)
            [tempArray addObject:thread];
    }
//    threads = tempArray;
    threads = parser.parsedThreads;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return threads.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"thread_description_cell_identifier" forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell) {
        UITextView *contentTextView = (UITextView*)[cell viewWithTag:1];
        czzThread *thread = [threads objectAtIndex:indexPath.row];
        contentTextView.text = thread.description;
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    czzThread *thread = [threads objectAtIndex:indexPath.row];
    NSString *content = thread.description;
    CGFloat height = [content sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(self.view.frame.size.width, MAXFLOAT)].height;
    return height + 20;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    czzThreadViewController *threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_thread_view_controller"];
    threadViewController.parentThread = [threads objectAtIndex:0];
    [self.navigationController pushViewController:threadViewController animated:YES];
}
@end
