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

static NSString * cellIdentifier = @"cellIdentifier";

@interface czzAddForumTableViewController ()

@property (strong, nonatomic) UITextField *forumNameTextField;
@property (strong, nonatomic) UITextField *forumIDTextField;

@end

@implementation czzAddForumTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

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
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)editButtonAction:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

- (IBAction)addButtonAction:(id)sender {
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
    [alertConroller addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertConroller animated:YES completion:nil];
}

#pragma mark - UITextField actions.

- (void)textFieldDidChange:(UITextField*)sender {
    DLog(@"%@", sender.text);
    
}

@end
