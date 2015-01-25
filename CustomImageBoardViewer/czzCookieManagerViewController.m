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

#import "KLCPopup.h"

@interface czzCookieManagerViewController () <UITableViewDataSource, UITableViewDelegate>
@property czzCookieManager *cookieManager;
@end

@implementation czzCookieManagerViewController
@synthesize cookieManagerTableView;
@synthesize cookieManager;

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
    UILabel *nameLabel = (UILabel*) [cell viewWithTag:2];
    UILabel *contentLabel = (UILabel*) [cell viewWithTag:1];
    
    NSHTTPCookie *cookie = [[cookieManager currentACCookies] objectAtIndex:indexPath.row];
    nameLabel.text = cookie.name;
    contentLabel.text = cookie.value;
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController setToolbarHidden:NO animated:YES];
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

-(void)refreshData {
    [cookieManager refreshACCookies];
    [cookieManagerTableView reloadData];
}
@end
