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

#define THREAD_VIEW_CELL_MARGIN 4 * 2

#define THREAD_TABLE_VLEW_CELL_NIB_NAME @"czzThreadViewTableViewCell"
#define BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME @"czzThreadViewBigImageTableViewCell"
#define BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER @"thread_big_image_cell_identifier"
#define THREAD_VIEW_CELL_IDENTIFIER @"thread_cell_identifier"

#import <UIKit/UIKit.h>
#import "czzThread.h"


@protocol czzMenuEnabledTableViewCellProtocol <NSObject>
@optional
-(void)userTapInQuotedText:(NSString*)text;
-(void)userTapInImageView:(NSString*)imgURL;
// Menu actions
- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread;
- (void)userWantsToHighLight:(czzThread *)thread;
- (void)userWantsToSearch:(czzThread *)thread;
@end

@interface czzMenuEnabledTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UIView *threadContentView;
@property NSIndexPath *myIndexPath;

@property (strong, nonatomic) NSString *selectedUserToHighlight;
@property (weak, nonatomic) id<czzMenuEnabledTableViewCellProtocol> delegate;

@property NSDictionary *downloadedImages;
@property (assign, nonatomic) BOOL shouldHighlight;
@property (assign, nonatomic) BOOL shouldAllowClickOnImage;
@property NSMutableArray *links;
@property czzThread *parentThread;
@property (nonatomic) czzThread *myThread;

@end


/*
 UITextView *contentTextView = (UITextView*)[cell viewWithTag:1];
 UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
 UILabel *posterLabel = (UILabel*)[cell viewWithTag:3];
 UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
 UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
 UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];

*/