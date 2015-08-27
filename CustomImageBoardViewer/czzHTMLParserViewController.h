//
//  czzHTMLParserViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/10/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzHTMLParserViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@property NSURL *targetURL;
@property (strong, nonatomic) NSString *highlightKeyword;
@end
