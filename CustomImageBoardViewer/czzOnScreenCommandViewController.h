//
//  czzOnScreenCommandViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol czzOnScreenCommandViewControllerDelegate <NSObject>
-(void)onScreenCommandTapOnUp:(id)sender;
-(void)onScreenCommandTapOnDown:(id)sender;
@end

@class czzThreadTableView;
@interface czzOnScreenCommandViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *upperButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (weak, nonatomic) czzThreadTableView<czzOnScreenCommandViewControllerDelegate> *delegate;

@property CGSize size;
@property NSTimeInterval timeoutInterval;
- (IBAction)upButtonAction:(id)sender;
- (IBAction)bottomButtonAction:(id)sender;

-(void)show;
-(void)hide;
@end
