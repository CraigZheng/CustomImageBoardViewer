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
#import "czzSettingsCentre.h"

@interface czzFavouriteManagerViewController ()
@property NSIndexPath *selectedIndex;
@property NSMutableSet *internalThreads;
@property czzThread *selectedThread;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzFavouriteManagerViewController
@synthesize internalThreads;
@synthesize selectedIndex;
@synthesize threads;
@synthesize title;
@synthesize selectedThread;
@synthesize settingsCentre;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"czzThreadViewTableViewCell" bundle:nil] forCellReuseIdentifier:@"thread_cell_identifier"];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    settingsCentre = [czzSettingsCentre sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!threads) {
        NSString* libraryPath = [czzAppDelegate libraryFolder];
        internalThreads = [NSKeyedUnarchiver unarchiveObjectWithFile:[libraryPath stringByAppendingPathComponent:@"favourites.dat"]];
        if (!internalThreads){
            internalThreads = [NSMutableSet new];
        }
        threads = [NSMutableArray arrayWithArray:[self sortTheGivenArray:internalThreads.allObjects]];
    }
    if (title) {
        self.title = title;
    }
    self.view.backgroundColor = settingsCentre.viewBackgroundColour;
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSString* libraryPath = [czzAppDelegate libraryFolder];
    internalThreads = [NSMutableSet setWithArray:threads];
    [NSKeyedArchiver archiveRootObject:internalThreads toFile:[libraryPath stringByAppendingPathComponent:@"favourites.dat"]];
}

#pragma UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return threads.count;
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *cell_identifier = @"thread_cell_identifier";
//    czzThread *thread = [internalThreads.allObjects objectAtIndex:indexPath.row];
    czzThread *thread = [threads objectAtIndex:indexPath.row];

    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
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
        [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        czzThread* threadToDelete = [threads objectAtIndex:indexPath.row];
        [threads removeObject:threadToDelete];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row >= threads.count)
        return tableView.rowHeight;
    
    czzThread *thread;
    @try {
        thread = [threads objectAtIndex:indexPath.row];
    }
    @catch (NSException *exception) {
        
    }
    if (thread){
        CGFloat preferHeight = 0;
        UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        newHiddenTextView.hidden = YES;
        [self.view addSubview:newHiddenTextView];
        newHiddenTextView.attributedText = thread.content;
        preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 20;
        [newHiddenTextView removeFromSuperview];
        //height for preview image
        if (thread.thImgSrc.length != 0) {
            preferHeight += 82;
            
        }
        return MAX(tableView.rowHeight, preferHeight);
    }
    return tableView.rowHeight;
}

- (IBAction)editAction:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

#pragma sort array - sort the threads so they arrange with ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:NO];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    /*
     NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
     czzThread *first = (czzThread*)a;
     czzThread *second = (czzThread*)b;
     return first.ID > second.ID;
     }];
     */
    return sortedArray;
}

#pragma prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go_thread_view_segue"]) {
        czzThreadViewController *threadViewController = (czzThreadViewController*)segue.destinationViewController;
        threadViewController.parentThread = selectedThread;
    }
}

#pragma mark - rotation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
}
@end
