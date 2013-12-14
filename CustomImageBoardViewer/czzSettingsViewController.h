//
//  czzSettingsViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzSettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *settingsTableView;

@end
