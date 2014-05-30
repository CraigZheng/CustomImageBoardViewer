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

@interface czzFavouriteManagerViewController ()
@property NSMutableSet *threads;
@property NSIndexPath *selectedIndex;
@end

@implementation czzFavouriteManagerViewController
@synthesize threads;
@synthesize selectedIndex;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    threads = [NSKeyedUnarchiver unarchiveObjectWithFile:[libraryPath stringByAppendingPathComponent:@"favourites.dat"]];
    if (!threads){
        threads = [NSMutableSet new];
    }
    threads = [NSMutableSet setWithArray:[self sortTheGivenArray:threads.allObjects]];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [NSKeyedArchiver archiveRootObject:threads toFile:[libraryPath stringByAppendingPathComponent:@"favourites.dat"]];
}

#pragma UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return threads.count;
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *cell_identifier = @"thread_cell_identifier";
    czzThread *thread = [threads.allObjects objectAtIndex:indexPath.row];
    //if image is present and settins is set to allow images to show
    if (thread.thImgSrc.length != 0){
        cell_identifier = @"image_thread_cell_identifier";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        UITextView *contentTextView = (UITextView*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *responseLabel = (UILabel*)[cell viewWithTag:4];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
        UILabel *imgLabel = (UILabel*)[cell viewWithTag:6];
        UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
        UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];
        UIImageView *previewImageView = (UIImageView*)[cell viewWithTag:9];
        previewImageView.hidden = YES;
        if (thread.thImgSrc != 0){
            previewImageView.hidden = NO;
            [previewImageView setImage:[UIImage imageNamed:@"Icon.png"]];
            NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            basePath = [basePath stringByAppendingPathComponent:@"Thumbnails"];
            NSString *filePath = [basePath stringByAppendingPathComponent:[thread.thImgSrc.lastPathComponent stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
            UIImage *previewImage =[UIImage imageWithContentsOfFile:filePath];
            if (previewImage){
                [previewImageView setImage:previewImage];
            }
        }
        [contentTextView setAttributedText:thread.content];

        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        [responseLabel setText:[NSString stringWithFormat:@"回应:%ld", (long)thread.responseCount]];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"时间:MM-dd, HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:thread.postDateTime];
        if (thread.imgSrc.length == 0)
            [imgLabel setHidden:YES];
        else
            [imgLabel setHidden:NO];
        if (thread.sage)
            [sageLabel setHidden:NO];
        else
            [sageLabel setHidden:YES];
        if (thread.lock)
            [lockLabel setHidden:NO];
        else
            [lockLabel setHidden:YES];
        if (thread.imgSrc.length == 0)
            [imgLabel setHidden:YES];
        else
            [imgLabel setHidden:NO];
        
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        czzThread *selectedThread = [threads.allObjects objectAtIndex:selectedIndex.row];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:selectedThread forKey:@"PickedThread"];
        [self.viewDeckController toggleTopViewAnimated:YES completion:^(IIViewDeckController *controller, BOOL success){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FavouriteThreadPicked" object:self userInfo:userInfo];
        }];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        czzThread* threadToDelete = [threads.allObjects objectAtIndex:indexPath.row];
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
        thread = [threads.allObjects objectAtIndex:indexPath.row];
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

#pragma mark - rotation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
}
@end
