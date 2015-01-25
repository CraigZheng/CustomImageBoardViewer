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

#import "KLCPopup.h"

@interface czzCookieManagerViewController () <UITableViewDataSource, UITableViewDelegate>
@property czzCookieManager *cookieManager;
@property NSHTTPCookie *selectedCookie;
@end

@implementation czzCookieManagerViewController
@synthesize cookieManagerTableView;
@synthesize cookieManager;
@synthesize selectedCookie;

static NSString *cookie_info_tableview_cell_identifier = @"cookie_info_table_view_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    cookieManager = [czzCookieManager new];
    [cookieManager refreshACCookies];
}


#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cookieManager currentACCookies].count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cookie_info_tableview_cell_identifier forIndexPath:indexPath];
    UILabel *domainLabel = (UILabel*) [cell viewWithTag:3];
    UILabel *nameLabel = (UILabel*) [cell viewWithTag:2];
    UILabel *contentLabel = (UILabel*) [cell viewWithTag:1];
    
    NSHTTPCookie *cookie = [[cookieManager currentACCookies] objectAtIndex:indexPath.row];
    nameLabel.text = cookie.name;
    contentLabel.text = cookie.value;
    domainLabel.text = cookie.domain;
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedCookie = [[cookieManager currentACCookies] objectAtIndex:indexPath.row];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        NSHTTPCookie *cookieToDelete = [[cookieManager currentACCookies] objectAtIndex:indexPath.row];
        [cookieManager deleteCookie:cookieToDelete];
        [self refreshData];
    }
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:COOKIE_MANAGER_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateInitialViewController];
}
- (IBAction)reloadAction:(id)sender {
    [self refreshData];
    if ([cookieManager currentACCookies].count == 0) {
        [[czzMessagePopUpViewController new] show];
    }
}

- (IBAction)useCookieAction:(id)sender {
    NSHTTPCookie *newCookie = [czzACTokenUtil createCookieWithValue:selectedCookie.value forURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
    if (newCookie) {
        [cookieManager setACCookie:newCookie ForURL:[NSURL URLWithString:[settingCentre a_isle_host]]];
        [self refreshData];
    } else {
        DLog(@"token nil");
    }
}

- (IBAction)shareCookieAction:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[selectedCookie.value] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)deleteCookieAction:(id)sender {
    [cookieManager deleteCookie:selectedCookie];
    [self refreshData];
}

-(void)refreshData {
    [cookieManager refreshACCookies];
    [cookieManagerTableView reloadData];
}
@end
