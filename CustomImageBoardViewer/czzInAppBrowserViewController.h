//
//  czzInAppBrowserViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzInAppBrowserViewController : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *browserNaviBar;
@property (weak, nonatomic) IBOutlet UIWebView *browserWebView;

@property NSURL *targetURL;
- (IBAction)dismissAction:(id)sender;
@end
