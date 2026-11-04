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

- (void)viewDidLoad {
  [super viewDidLoad];
  cookieManager = CookieManager;

  UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"新鲜", @"保鲜"]];
  segmentControl.selectedSegmentIndex = 0;
  [segmentControl addTarget:self action:@selector(cookieManagerSegmentControlAction:) forControlEvents:UIControlEventValueChanged];
  self.navigationItem.titleView = segmentControl;
  self.cookieManagerSegmentControl = segmentControl;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_user.png"] style:UIBarButtonItemStylePlain target:self action:@selector(addCookieAction:)];

  cookieManagerTableView.backgroundColor = [settingCentre viewBackgroundColour];
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([cookieManager currentACCookies].count <= 0) {
      [self addCookieAction:self];
    }
  });
}

- (void)loadView {
  UIView *rootView = [[UIView alloc] init];
  rootView.backgroundColor = [UIColor whiteColor];
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  tableView.translatesAutoresizingMaskIntoConstraints = NO;
  tableView.rowHeight = 60;
  tableView.dataSource = self;
  tableView.delegate = self;
  tableView.backgroundColor = [UIColor whiteColor];
  [rootView addSubview:tableView];
  [NSLayoutConstraint activateConstraints:@[
    [tableView.topAnchor constraintEqualToAnchor:rootView.topAnchor],
    [tableView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
    [tableView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
    [tableView.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor]
  ]];
  self.view = rootView;
  self.cookieManagerTableView = tableView;
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.selectedCookie = nil;
  [self refreshData];
}

#pragma mark - Segue

-(void)showCookieDetailForCookie:(NSHTTPCookie *)cookie {
  CookieDetailTableViewController *cookieDetailTableViewController = [[CookieDetailTableViewController alloc] initWithStyle:UITableViewStylePlain];
  SettingsHost activeHost = SettingsHostAC;
  if (cookie) {
    if ([settingCentre.ac_isle_host containsString:cookie.domain]) {
      activeHost = SettingsHostAC;
    } else if ([settingCentre.bt_isle_host containsString:cookie.domain]) {
      activeHost = SettingsHostBT;
    }
    cookieDetailTableViewController.cookieValue = cookie.value;
    cookieDetailTableViewController.originalCookie = cookie;
    cookieDetailTableViewController.isOriginalCookieFromArchive = self.cookieManagerSegmentControl.selectedSegmentIndex == 1;
  }
  cookieDetailTableViewController.isEditable = true;
  cookieDetailTableViewController.activeHost = activeHost;
  [self.navigationController pushViewController:cookieDetailTableViewController animated:YES];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return cookiesDataSource.count;
}

-(UITableViewCell *)cookieInfoCellForTableView:(UITableView *)tableView {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cookie_info_tableview_cell_identifier];
  if (cell) {
    return cell;
  }
  cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cookie_info_tableview_cell_identifier];
  UILabel *contentLabel = [self cookieLabelWithTag:1 font:[UIFont systemFontOfSize:14] color:[UIColor blackColor]];
  contentLabel.numberOfLines = 0;
  contentLabel.minimumScaleFactor = 0.5;
  contentLabel.adjustsFontSizeToFitWidth = YES;
  [contentLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
  UILabel *nameLabel = [self cookieLabelWithTag:2 font:[UIFont boldSystemFontOfSize:15] color:[UIColor blackColor]];
  nameLabel.numberOfLines = 0;
  nameLabel.minimumScaleFactor = 0.5;
  nameLabel.adjustsFontSizeToFitWidth = YES;
  UILabel *domainLabel = [self cookieLabelWithTag:3 font:[UIFont systemFontOfSize:15] color:[UIColor colorWithWhite:0.667 alpha:1]];
  domainLabel.minimumScaleFactor = 0.5;
  domainLabel.adjustsFontSizeToFitWidth = YES;
  [domainLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
  UILabel *expiryLabel = [self cookieLabelWithTag:4 font:[UIFont systemFontOfSize:12] color:[UIColor colorWithRed:1 green:0.6795437536 blue:0.06947360188 alpha:1]];
  expiryLabel.minimumScaleFactor = 0.5;
  expiryLabel.adjustsFontSizeToFitWidth = YES;
  [expiryLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
  [cell.contentView addSubview:nameLabel];
  [cell.contentView addSubview:contentLabel];
  [cell.contentView addSubview:domainLabel];
  [cell.contentView addSubview:expiryLabel];
  [NSLayoutConstraint activateConstraints:@[
    [nameLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
    [nameLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
    [nameLabel.widthAnchor constraintEqualToConstant:70],
    [contentLabel.leadingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor],
    [contentLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
    [contentLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
    [contentLabel.bottomAnchor constraintEqualToAnchor:nameLabel.bottomAnchor],
    [domainLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
    [domainLabel.topAnchor constraintEqualToAnchor:contentLabel.bottomAnchor],
    [domainLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
    [expiryLabel.leadingAnchor constraintEqualToAnchor:domainLabel.trailingAnchor],
    [expiryLabel.topAnchor constraintEqualToAnchor:domainLabel.topAnchor],
    [expiryLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
    [cell.contentView.trailingAnchor constraintEqualToAnchor:expiryLabel.trailingAnchor constant:20]
  ]];
  return cell;
}

- (UILabel *)cookieLabelWithTag:(NSInteger)tag font:(UIFont *)font color:(UIColor *)color {
  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.tag = tag;
  label.font = font;
  label.textColor = color;
  label.textAlignment = NSTextAlignmentCenter;
  return label;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [self cookieInfoCellForTableView:tableView];
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
  [self showCookieDetailForCookie:self.selectedCookie];
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
  QRCodeScannerViewController *scanner = [[QRCodeScannerViewController alloc] init];
  [self.navigationController pushViewController:scanner animated:YES];
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
  return [[self alloc] init];
}

@end
