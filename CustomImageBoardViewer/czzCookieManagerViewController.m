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
#import "czzBannerNotificationUtil.h"

#import "CustomImageBoardViewer-Swift.h"

@interface czzCookieManagerViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property czzCookieManager *cookieManager;
@property (nonatomic, strong) NSHTTPCookie *selectedCookie;
@property NSArray *cookiesDataSource;
@end

@implementation czzCookieManagerViewController
@synthesize cookieManagerTableView;
@synthesize cookieManager;
@synthesize cookiesDataSource;
@synthesize cookieManagerSegmentControl;
@synthesize saveCookieBarButtonItem;
@synthesize addCookieAlertView, useCookieAlertView, shareCookieAlertView, saveCookieAlertView, deleteCookieAlertView;

static NSString *cookie_info_tableview_cell_identifier = @"cookie_info_table_view_cell_identifier";

static NSString *kCookieDetailsSegueIdentifier = @"cookieDetail";
static NSString *kScanQRCodeSegueIdentifier = @"qrScanner";

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  cookieManager = CookieManager;
  
  cookieManagerTableView.backgroundColor = [settingCentre viewBackgroundColour];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // Google Analytic integration
  id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
  [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
  [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
  self.selectedCookie = nil;
  [self refreshData];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.destinationViewController isKindOfClass:CookieDetailTableViewController.class]) {
    CookieDetailTableViewController *cookieDetailTableViewController = (CookieDetailTableViewController *)segue.destinationViewController;
    SettingsHost activeHost = SettingsHostAC;
    if (self.selectedCookie) {
      if ([settingCentre.ac_isle_host containsString:self.selectedCookie.domain]) {
        activeHost = SettingsHostAC;
      } else if ([settingCentre.bt_isle_host containsString:self.selectedCookie.domain]) {
        activeHost = SettingsHostBT;
      }
      cookieDetailTableViewController.cookieValue = self.selectedCookie.value;
      cookieDetailTableViewController.originalCookie = self.selectedCookie;
      cookieDetailTableViewController.isOriginalCookieFromArchive = self.cookieManagerSegmentControl.selectedSegmentIndex == 1;
    }
    cookieDetailTableViewController.activeHost = activeHost;
  }
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return cookiesDataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cookie_info_tableview_cell_identifier forIndexPath:indexPath];
    UILabel *expiryLabel = (UILabel *)[cell viewWithTag:4];
    UILabel *domainLabel = (UILabel*) [cell viewWithTag:3];
    UILabel *nameLabel = (UILabel*) [cell viewWithTag:2];
    UILabel *contentLabel = (UILabel*) [cell viewWithTag:1];
    
    NSHTTPCookie *cookie = [cookiesDataSource objectAtIndex:indexPath.row];
    nameLabel.text = cookie.name;
    contentLabel.text = cookie.value;
    domainLabel.text = cookie.domain;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"dd/MMM/yyyy";
    expiryLabel.text = [NSString stringWithFormat:@"有效期至:%@", [dateFormatter stringFromDate:cookie.expiresDate]];
    
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
  self.selectedCookie = [cookiesDataSource objectAtIndex:indexPath.row];
  [self performSegueWithIdentifier:kCookieDetailsSegueIdentifier sender:tableView];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
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

- (IBAction)unwindToCookieManagerViewController:(UIStoryboardSegue *)sender {
  // Unwind segue.
}

-(void)showConfirmDeleteAlertView {
    deleteCookieAlertView = [[UIAlertView alloc] initWithTitle:@"删除饼干" message:@"这个饼干将会被删除" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [deleteCookieAlertView show];
}

- (IBAction)cookieManagerSegmentControlAction:(id)sender {
    self.selectedCookie = nil;
    [self refreshData];
}

- (IBAction)addCookieAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"手动添加" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"扫二维码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performSegueWithIdentifier:kScanQRCodeSegueIdentifier sender:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"手动写入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performSegueWithIdentifier:kCookieDetailsSegueIdentifier sender:sender];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController.popoverPresentationController setSourceView:self.view];
    [alertController.popoverPresentationController setSourceRect:CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 0, 0)];
    [alertController.popoverPresentationController setPermittedArrowDirections:0];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)refreshData {
    switch (cookieManagerSegmentControl.selectedSegmentIndex) {
        case 0:
            cookiesDataSource = [cookieManager currentACCookies];
            break;
        case 1:
            cookiesDataSource = [cookieManager archivedCookies];
            break;
        default:
            cookiesDataSource = [cookieManager currentACCookies];
            break;
    }

    [cookieManagerTableView reloadData];

}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex == buttonIndex)
        return;
    
    if (alertView == saveCookieAlertView) {
        [cookieManager archiveCookie:self.selectedCookie];
        [czzBannerNotificationUtil displayMessage:@"饼干已放入保鲜库" position:BannerNotificationPositionTop];
    } else if (alertView == useCookieAlertView) {
        NSHTTPCookie *newCookie = [czzACTokenUtil createCookieWithValue:self.selectedCookie.value forURL:[NSURL URLWithString:[settingCentre activeHost]]];
        if (newCookie) {
            [cookieManager setACCookie:newCookie ForURL:[NSURL URLWithString:[settingCentre activeHost]]];
            [czzBannerNotificationUtil displayMessage:@"饼干已启用" position:BannerNotificationPositionTop];
        } else {
            DDLogDebug(@"token nil");
        }
    } else if (alertView == shareCookieAlertView) {
        //do nothing
    } else if (alertView == deleteCookieAlertView) {
        if (cookieManagerSegmentControl.selectedSegmentIndex == 0) {
            [cookieManager deleteCookie:self.selectedCookie];
        } else if (cookieManagerSegmentControl.selectedSegmentIndex == 1) {
            [cookieManager deleteArchiveCookie:self.selectedCookie];
        }
        [czzBannerNotificationUtil displayMessage:@"饼干已删除" position:BannerNotificationPositionTop];
    } else if (alertView == addCookieAlertView) {
        UITextField *textField = [addCookieAlertView textFieldAtIndex:0];
        NSString *text = textField.text;
        if (text.length)
        {
            if ([cookieManager addValueAsCookie:text]) {
                [czzBannerNotificationUtil displayMessage:@"饼干已添加" position:BannerNotificationPositionTop];
            } else {
                [czzBannerNotificationUtil displayMessage:@"饼干添加失败，请检查输入" position:BannerNotificationPositionTop];
            }
        }
    }
    [self refreshData];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:COOKIE_MANAGER_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:CZZ_COOKIE_MANAGER_VIEW_CONTROLLER_IDENTIFIER];
}

@end
