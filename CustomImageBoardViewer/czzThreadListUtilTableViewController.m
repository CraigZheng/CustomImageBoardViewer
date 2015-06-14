//
//  czzThreadListUtilTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 14/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadListUtilTableViewController.h"
#import "czzAppDelegate.h"
#import "czzThreadViewModelManager.h"

@interface czzThreadListUtilTableViewController ()
@property NSArray *cacheFiles;
@end

@implementation czzThreadListUtilTableViewController
@synthesize cacheFiles;

NSString* const cellIdentifier = @"cellIdentifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Load data from threadCacheFolder
    NSError *error;
    cacheFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[czzAppDelegate threadCacheFolder] error:&error];
    if (error) {
        DLog(@"%@", error);
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return cacheFiles.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSString *cacheFile = [cacheFiles objectAtIndex:indexPath.row];
    // Configure the cell...
    if (cell) {
        cell.textLabel.text = cacheFile;
        czzThreadViewModelManager *viewModelManager = [self readThreadViewModelWithCacheFile:cacheFile];
        if (viewModelManager) {
            cell.detailTextLabel.text = viewModelManager.parentThread.description;
        }
    }
    
    return cell;
}

-(czzThreadViewModelManager*)readThreadViewModelWithCacheFile:(NSString*)file {
    if (!file.length) {
        return nil;
    }
    NSString *filePath = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:file];
    return [[czzThreadViewModelManager alloc] restoreWithFile:filePath];
}

- (IBAction)launchButtonAction:(id)sender {
    UIViewController *mainViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateInitialViewController];
    if (mainViewController) {
        [czzAppDelegate sharedAppDelegate].window.rootViewController = mainViewController;
        [[czzAppDelegate sharedAppDelegate].window makeKeyAndVisible];
    } else {
        DLog(@"Cannot instantiate initial view controller from main storyboard.");
    }
}
@end
