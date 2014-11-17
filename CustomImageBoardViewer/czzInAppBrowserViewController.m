//
//  czzInAppBrowserViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 17/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzInAppBrowserViewController.h"

@interface czzInAppBrowserViewController ()

@end

@implementation czzInAppBrowserViewController
@synthesize browserNaviBar;
@synthesize browserWebView;
@synthesize targetURL;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (targetURL)
        [browserWebView loadRequest:[NSURLRequest requestWithURL:targetURL]];
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
