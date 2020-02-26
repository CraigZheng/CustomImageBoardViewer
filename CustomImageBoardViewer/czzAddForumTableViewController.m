//
//  czzAddForumTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 24/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzAddForumTableViewController.h"

#import "czzForum.h"
#import "czzForumManager.h"
#import "SlideNavigationController.h"

static NSString * cellIdentifier = @"cellIdentifier";

@interface czzAddForumTableViewController ()

@property (strong, nonatomic) UITextField *forumNameTextField;
@property (strong, nonatomic) UITextField *forumIDTextField;
@property (strong, nonatomic) NSString *forumName;
@property (assign, nonatomic) NSInteger forumID;
@end

@implementation czzAddForumTableViewController

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [czzForumManager sharedManager].customForums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                            forIndexPath:indexPath];
    czzForum *forum = [czzForumManager sharedManager].customForums[indexPath.row];
    cell.textLabel.text = forum.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)forum.forumID];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        czzForum *forum = [czzForumManager sharedManager].customForums[indexPath.row];
        [[czzForumManager sharedManager] removeCustomForum:forum];
        [self.tableView reloadData];
    }
}

#pragma mark - UI actions.

- (IBAction)cancelButtonAction:(id)sender {
    // Open the left view without animation before showing.
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)editButtonAction:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

- (IBAction)addButtonAction:(id)sender {
    // Reset things.
    self.forumID = 0;
    self.forumName = nil;
    self.forumIDTextField = self.forumNameTextField = nil;
    UIAlertController *alertConroller = [UIAlertController alertControllerWithTitle:@"自定义板块" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertConroller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入名称";
        [textField addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
        self.forumNameTextField = textField;
    }];
    [alertConroller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入ID";
        [textField addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
        self.forumIDTextField = textField;
    }];
    [alertConroller addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.forumName.length && self.forumID >= 0) {
            [[czzForumManager sharedManager] addCustomForumWithName:self.forumName forumID:self.forumID];
            [self.tableView reloadData];
        }
    }]];
    [alertConroller addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [[alertConroller popoverPresentationController] setSourceView:self.view];
    [[alertConroller popoverPresentationController] setSourceRect:CGRectMake(self.view.bounds.origin.x / 2, self.view.bounds.origin.y / 2, 0, 0)];
    [self presentViewController:alertConroller animated:YES completion:nil];
}

#pragma mark - UITextField actions.

- (void)textFieldDidChange:(UITextField*)sender {
    DLog(@"%@", sender.text);
    if (sender == self.forumNameTextField) {
        self.forumName = sender.text;
    } else if (sender == self.forumIDTextField) {
        self.forumID = sender.text.integerValue;
    }
}

@end
