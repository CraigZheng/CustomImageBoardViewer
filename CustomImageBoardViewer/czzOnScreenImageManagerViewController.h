//
//  czzOnScreenImageManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class czzOnScreenImageManagerViewController;
@protocol czzOnScreenImageManagerViewControllerDelegate <NSObject>
@optional
-(void)onScreenImageManagerDownloadFinished:(czzOnScreenImageManagerViewController*)controller imagePath:(NSString*)path wasSuccessful:(BOOL)success;
-(void)onScreenImageManagerSelectedImage:(NSString*)path;
@end

@interface czzOnScreenImageManagerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *mainIcon;
@property (weak, nonatomic) id<czzOnScreenImageManagerViewControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *downloadedImages;

- (IBAction)tapOnImageManagerIconAction:(id)sender;

-(void)startAnimating;
-(void)stopAnimating;
@end
