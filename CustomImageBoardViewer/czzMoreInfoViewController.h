//
//  czzMoreInfoViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"

@interface czzMoreInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *headerTextWebView;
@property (nonatomic) NSString *forumName;
- (IBAction)sendEmailAction:(id)sender;
- (IBAction)homePageAction:(id)sender;
@end
