//
//  czzDebugSettingsTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 22/12/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzDebugSettingsTableViewController.h"
#import "czzSettingsCentre.h"

static NSString * const settingsIdentifier = @"settings_identifier";

@interface czzDebugSettingsTableViewController ()
@property (nonatomic, copy) NSArray *propertiyKeys;
@end

@implementation czzDebugSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:settingsIdentifier];
    NSDictionary *properties = [NSObject classPropsFor:[settingCentre class]];
    self.propertiyKeys = [properties.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

#pragma mark - Cell construction

/// The prototype cell from the old storyboard: title over a wrapping description.
- (UITableViewCell *)debugCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:settingsIdentifier forIndexPath:indexPath];

    UILabel *titleLabel = [cell.contentView viewWithTag:1];
    if (!titleLabel) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.tag = 1;
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.numberOfLines = 0;
        [cell.contentView addSubview:titleLabel];

        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        descriptionLabel.tag = 2;
        descriptionLabel.font = [UIFont systemFontOfSize:14];
        descriptionLabel.numberOfLines = 0;
        [cell.contentView addSubview:descriptionLabel];

        CGFloat inset = 8;
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [titleLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:inset],
            [cell.contentView.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor constant:inset],

            [descriptionLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
            [descriptionLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:inset],
            [cell.contentView.trailingAnchor constraintEqualToAnchor:descriptionLabel.trailingAnchor constant:inset],
            [cell.contentView.bottomAnchor constraintEqualToAnchor:descriptionLabel.bottomAnchor constant:inset]
        ]];
    }
    return cell;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.propertiyKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self debugCellForTableView:tableView indexPath:indexPath];
    
    // Configure the cell...
    if (cell) {
        UILabel *titleLabel = [cell viewWithTag:1];
        UILabel *descriptionLabel = [cell viewWithTag:2];
        
        NSString *propertyKey = self.propertiyKeys[indexPath.row];
        id value = [settingCentre valueForKey:propertyKey];
        
        titleLabel.text = propertyKey;
        if ([value isKindOfClass:[NSString class]]) {
            descriptionLabel.text = value;
        } else {
            descriptionLabel.text = [NSString stringWithFormat:@"%@", value];
        }
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
