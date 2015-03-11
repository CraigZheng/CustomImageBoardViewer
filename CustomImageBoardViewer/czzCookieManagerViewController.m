//
//  czzCookieManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzCookieManagerViewController.h"
#import "czzCookieManager.h"
#import "czzMessagePopUpViewController.h"
#import "czzACTokenUtil.h"
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"

#import "KLCPopup.h"

@interface czzCookieManagerViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property czzCookieManager *cookieManager;
@property NSHTTPCookie *selectedCookie;
@property NSArray *cookiesDataSource;

@end

@implementation czzCookieManagerViewController
@synthesize cookieManagerTableView;
@synthesize cookieManager;
@synthesize selectedCookie;
@synthesize cookiesDataSource;
@synthesize cookieManagerSegmentControl;
@synthesize saveCookieBarButtonItem;
@synthesize addCookieAlertView, useCookieAlertView, shareCookieAlertView, saveCookieAlertView, deleteCookieAlertView;

static NSString *cookie_info_tableview_cell_identifier = @"cookie_info_table_view_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    cookieManager = [czzCookieManager new];
    [self refreshData];
    
    cookieManagerTableView.backgroundColor = [settingCentre viewBackgroundColour];
}


#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return cookiesDataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cookie_info_tableview_cell_identifier forIndexPath:indexPath];
    UILabel *domainLabel = (UILabel*) [cell viewWithTag:3];
    UILabel *nameLabel = (UILabel*) [cell viewWithTag:2];
    UILabel *contentLabel = (UILabel*) [cell viewWithTag:1];
    
    NSHTTPCookie *cookie = [cookiesDataSource objectAtIndex:indexPath.row];
    nameLabel.text = cookie.name;
    contentLabel.text = cookie.value;
    domainLabel.text = cookie.domain;
    
    //colour for nighty mode
    nameLabel.textColor = contentLabel.textColor = [settingCentre contentTextColour];
    //highlight the currently in use cookie
    NSHTTPCookie *inUseCookie = [cookieManager currentInUseCookie];
    if ([cookie.domain isEqual:inUseCookie.domain] && [cookie.value isEqualToString:inUseCookie.value]) {
        cell.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        cell.contentView.backgroundColor = [settingCentre viewBackgroundColour];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedCookie = [cookiesDataSource objectAtIndex:indexPath.row];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        [self showConfirmDeleteAlertView];
    }
}

- (IBAction)editAction:(id)sender {
    [self refreshData];
    [cookieManagerTableView setEditing:!cookieManagerTableView.isEditing animated:YES];
}

- (IBAction)useCookieAction:(id)sender {
    useCookieAlertView = [[UIAlertView alloc] initWithTitle:@"使用饼干" message:@"这个饼干将会被激活" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [useCookieAlertView show];
}

- (IBAction)shareCookieAction:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[selectedCookie.value] applicationActivities:nil];
    if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] ) { // iOS8
        activityViewController.popoverPresentationController.sourceView = self.view;
    }
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)saveCookieAction:(id)sender {
    saveCookieAlertView = [[UIAlertView alloc] initWithTitle:@"保存饼干" message:@"这个饼干将会被放入保鲜库" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [saveCookieAlertView show];
}

- (IBAction)deleteCookieAction:(id)sender {
    [self showConfirmDeleteAlertView];
}

-(void)showConfirmDeleteAlertView {
    deleteCookieAlertView = [[UIAlertView alloc] initWithTitle:@"删除饼干" message:@"这个饼干将会被删除" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [deleteCookieAlertView show];
}

- (IBAction)cookieManagerSegmentControlAction:(id)sender {
    selectedCookie = nil;
    [self.navigationController setToolbarHidden:YES animated:YES];
    [self refreshData];
}

- (IBAction)addCookieAction:(id)sender {
    addCookieAlertView = [[UIAlertView alloc] initWithTitle:@"手动添加" message:@"手动写入一个饼干的号码" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    addCookieAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [addCookieAlertView show];
}

-(void)refreshData {
    [cookieManager refreshACCookies];
    
    switch (cookieManagerSegmentControl.selectedSegmentIndex) {
        case 0:
            cookiesDataSource = [cookieManager currentACCookies];
            saveCookieBarButtonItem.enabled = YES;
            break;
        case 1:
            cookiesDataSource = [cookieManager archivedCookies];
            saveCookieBarButtonItem.enabled = NO;
            break;
        default:
            cookiesDataSource = [cookieManager currentACCookies];
            break;
    }
    if (cookiesDataSource.count == 0) {
        czzMessagePopUpViewController *messagePopUp = [czzMessagePopUpViewController new];
        messagePopUp.imageToShow = cookieManagerSegmentControl.selectedSegmentIndex == 0 ? [UIImage imageNamed:@"35.png"] : [UIImage imageNamed:@"03.png"];
        
        messagePopUp.messageToShow = [NSString stringWithFormat:@"没有%@的饼干...", [cookieManagerSegmentControl titleForSegmentAtIndex:cookieManagerSegmentControl.selectedSegmentIndex]];
        [messagePopUp show];
    }
    [cookieManagerTableView reloadData];

}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex == buttonIndex)
        return;
    
    if (alertView == saveCookieAlertView) {
        [cookieManager archiveCookie:selectedCookie];
        [[czzAppDelegate sharedAppDelegate] showToast:@"饼干已放入保鲜库"];
    } else if (alertView == useCookieAlertView) {
        NSHTTPCookie *newCookie = [czzACTokenUtil createCookieWithValue:selectedCookie.value forURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
        if (newCookie) {
            [cookieManager setACCookie:newCookie ForURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
            [[czzAppDelegate sharedAppDelegate] showToast:@"饼干已启用"];
        } else {
            DLog(@"token nil");
        }
    } else if (alertView == shareCookieAlertView) {
        //do nothing
    } else if (alertView == deleteCookieAlertView) {
        if (cookieManagerSegmentControl.selectedSegmentIndex == 0) {
            [cookieManager deleteCookie:selectedCookie];
        } else if (cookieManagerSegmentControl.selectedSegmentIndex == 1) {
            [cookieManager deleteArchiveCookie:selectedCookie];
        }
        [[czzAppDelegate sharedAppDelegate] showToast:@"饼干已删除"];
    } else if (alertView == addCookieAlertView) {
        UITextField *textField = [addCookieAlertView textFieldAtIndex:0];
        NSString *text = textField.text;
        if (text.length)
        {
            if ([cookieManager addValueAsCookie:text]) {
                [[czzAppDelegate sharedAppDelegate] showToast:@"饼干已添加"];
            } else {
                [[czzAppDelegate sharedAppDelegate] showToast:@"饼干添加失败，请检查输入"];
            }
        }
    }
    [self refreshData];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:COOKIE_MANAGER_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:CZZ_COOKIE_MANAGER_VIEW_CONTROLLER_IDENTIFIER];
}

@end
