//
//  czzEmotionPickerTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 6/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzEmotionPickerTableViewController.h"

@interface czzEmotionPickerTableViewController ()
@property NSArray *emotions;
@end

@implementation czzEmotionPickerTableViewController
@synthesize emotions;
@synthesize delegate;
@synthesize popoverController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    emotions = @[[NSNumber numberWithInteger:happy], [NSNumber numberWithInteger:sad]];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return emotions.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"emotion_cell_identifier" forIndexPath:indexPath];

    if (cell) {
        UIImageView *emoImageView = (UIImageView*)[cell viewWithTag:1];
        if (indexPath.row == 0)
        {
            [emoImageView setImage:[UIImage imageNamed:@"emotion_smile_icon.png"]];
        } else {
            [emoImageView setImage:[UIImage imageNamed:@"emotion_sad_icon.png"]];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (delegate) {
        if (indexPath.row == 0) {
            [delegate emotionPicked:happy];
        } else {
            [delegate emotionPicked:sad];
        }
    }

    if (popoverController) {
        [popoverController dismissPopoverAnimated:YES];
    }
}
@end
