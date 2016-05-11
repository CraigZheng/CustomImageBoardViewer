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
//#define BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER @"thread_big_image_cell_identifier"
#define THREAD_VIEW_CELL_IDENTIFIER @"thread_cell_identifier"

#import <UIKit/UIKit.h>
#import "czzThread.h"

extern NSInteger const threadCellImageViewNormalHeight;

typedef NS_ENUM(NSInteger, threadViewCellType) {
    threadViewCellTypeHome = 1,
    threadViewCellTypeThread = 2,
    threadViewCellTypeUndefined = 0
};

@class czzMenuEnabledTableViewCell;

@protocol czzMenuEnabledTableViewCellProtocol <NSObject>
@optional
-(void)userTapInQuotedText:(NSString*)text;
-(void)userTapInImageView:(NSString*)imgURL;
// Menu actions
- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread;
- (void)userWantsToHighLight:(czzThread *)thread;
- (void)userWantsToSearch:(czzThread *)thread;
// UI command
- (void)threadViewCellContentChanged:(czzMenuEnabledTableViewCell *)cell;
@end

@interface czzMenuEnabledTableViewCell : UITableViewCell
@property NSIndexPath *myIndexPath;

@property (strong, nonatomic) NSString *selectedUserToHighlight;
@property (weak, nonatomic) id<czzMenuEnabledTableViewCellProtocol> delegate;

@property NSDictionary *downloadedImages;
@property (assign, nonatomic) BOOL shouldHighlight;
@property (assign, nonatomic) BOOL shouldAllowClickOnImage;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) czzThread *parentThread;
@property (nonatomic, strong) czzThread *thread;
@property (nonatomic, assign) BOOL bigImageMode;
@property (nonatomic, assign) BOOL allowImage;
@property (nonatomic, assign) BOOL nightyMode;
@property (nonatomic, assign) threadViewCellType cellType;

- (void)renderContent;
- (void)highLight;

#pragma mark - Menu actions.
-(void)menuActionCopy:(id)sender;
-(void)menuActionReply:(id)sender;
-(void)menuActionOpen:(id)sender;
-(void)menuActionHighlight:(id)sender;
-(void)menuActionSearch:(id) sender;
@end