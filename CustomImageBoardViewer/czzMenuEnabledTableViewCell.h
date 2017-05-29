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
#define THREAD_VIEW_CELL_IDENTIFIER @"thread_cell_identifier"

#import <UIKit/UIKit.h>
#import "czzThread.h"
#import "czzImageDownloaderManager.h"

@import TTTAttributedLabel;

extern NSInteger kCellImageViewHeight;

typedef NS_ENUM(NSInteger, threadViewCellType) {
    threadViewCellTypeHome = 1,
    threadViewCellTypeThread = 2,
    threadViewCellTypeUndefined = 0
};

@class czzMenuEnabledTableViewCell, czzThreadViewCellHeaderView, czzThreadViewCellFooterView;

@protocol czzMenuEnabledTableViewCellProtocol <NSObject, TTTAttributedLabelDelegate>
@optional
-(void)userTapInQuotedText:(NSString*)text;
-(void)userTapInImageView:(id)sender;
// Menu actions
- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread;
- (void)userWantsToReport:(czzThread *)thread inParentThread:(czzThread *)parentThread;
- (void)userWantsToTemporarilyHighlightUser:(NSString *)UID;
- (void)userWantsToHighlightUser:(NSString *)UID;
- (void)userWantsToBlockUser:(NSString *)UID;
- (void)userWantsToSearch:(czzThread *)thread;
// UI command
- (void)threadViewCellContentChanged:(czzMenuEnabledTableViewCell *)cell;
@end

@interface czzMenuEnabledTableViewCell : UITableViewCell <czzImageDownloaderManagerDelegate>
@property NSIndexPath *myIndexPath;

@property (weak, nonatomic) id<czzMenuEnabledTableViewCellProtocol> delegate;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *contentLabel;
@property (weak, nonatomic) IBOutlet czzThreadViewCellHeaderView *cellHeaderView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellFooterView *cellFooterView;
@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (readonly, nonatomic) UIImage *placeholderImage;
@property NSDictionary *downloadedImages;
@property (assign, nonatomic) BOOL shouldBlock;
@property (assign, nonatomic) BOOL shouldAllowClickOnImage;
@property (nonatomic, assign) BOOL shouldTemporarilyHighlight;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) czzThread *parentThread;
@property (nonatomic, strong) czzThread *thread;
@property (nonatomic, assign) BOOL bigImageMode;
@property (nonatomic, assign) BOOL allowImage;
@property (nonatomic, assign) BOOL nightyMode;
@property (nonatomic, assign) threadViewCellType cellType;
@property (nonatomic, strong) UIColor *highlightColour;
@property (nonatomic, strong) NSString *nickname;

- (void)renderContent;
- (void)tapOnImageView:(id)sender;

#pragma mark - Menu actions.
- (void)menuActionCopy:(id)sender;
- (void)menuActionReply:(id)sender;
- (void)menuActionOpen:(id)sender;
- (void)menuActionTemporarilyHighlight:(id)sender;
- (void)menuActionHighlight:(id)sender;
- (void)menuActionSearch:(id)sender;
- (void)menuActionBlock:(id)sender;
- (void)menuActionReport:(id)sender;
@end
