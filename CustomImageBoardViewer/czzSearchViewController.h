//
//  czzSearchViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzSearchViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *searchWebView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *searchEngineSegmentedControl;
@property (strong, nonatomic) NSString *predefinedSearchKeyword;
- (IBAction)againAction:(id)sender;
- (IBAction)segmentControlChanged:(id)sender;
@end
