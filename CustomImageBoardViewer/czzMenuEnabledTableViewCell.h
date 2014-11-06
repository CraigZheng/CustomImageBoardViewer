//
//  czzMenuEnabledTableViewCell.h
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

/*
 sub class uitableview cell to enable custom menu action
 */

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "DACircularProgressView.h"


@protocol czzMenuEnabledTableViewCellProtocol <NSObject>
@optional
-(void)userTapInQuotedText:(NSString*)text;
-(void)userTapInImageView:(NSString*)imgURL;
@end

@interface czzMenuEnabledTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *posterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sageLabel;
@property (weak, nonatomic) IBOutlet UILabel *lockLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UILabel *responseLabel;
@property (weak, nonatomic) IBOutlet DACircularProgressView *circularProgressView;
@property NSString *shouldHighlightSelectedUser;
@property id<czzMenuEnabledTableViewCellProtocol> delegate;

@property NSDictionary *downloadedImages;
@property NSMutableArray *links;
@property czzThread *parentThread;
@property (nonatomic) czzThread *myThread;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapOnImageAction;
@end


/*
 UITextView *contentTextView = (UITextView*)[cell viewWithTag:1];
 UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
 UILabel *posterLabel = (UILabel*)[cell viewWithTag:3];
 UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
 UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
 UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];

*/