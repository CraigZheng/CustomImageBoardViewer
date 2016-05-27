//
//  czzThreadTableView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableView.h"

#import "czzMenuEnabledTableViewCell.h"
#import "czzBigImageModeTableViewCell.h"
#import "czzThreadTableViewCommandCellTableViewCell.h"
#import "czzOnScreenCommandViewController.h"

@interface czzThreadTableView () <czzOnScreenCommandViewControllerDelegate>

@end

@implementation czzThreadTableView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self registerNibs];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self registerNibs];
    }
    return self;
}

-(void)awakeFromNib {
    self.upDownViewController = [czzOnScreenCommandViewController new];
    self.upDownViewController.delegate = self;
    self.estimatedRowHeight = 44.0;
    self.rowHeight = UITableViewAutomaticDimension;
}

-(void)registerNibs {
    // Register thread view cells
    [self registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    [self registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];

    // Register thread view command cells
    [self registerNib:[UINib nibWithNibName:THREAD_TABLEVIEW_COMMAND_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER];
}

- (void)reloadData {
    [super reloadData];
}

-(void)scrollToTop:(BOOL)animated {
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        self.quickScrolling = YES;
        if ([self numberOfRowsInSection:0] > 0) {
            [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                        atScrollPosition:UITableViewScrollPositionTop
                                animated:animated];
        }
        else {
            [self setContentOffset:CGPointMake(0, -self.contentInset.top) animated:animated];
        }
        self.quickScrolling = NO;
    }];
}

#pragma mark - czzOnScreenCommandViewControllerDelegate
-(void)onScreenCommandTapOnUp:(id)sender {
    [self scrollToTop: YES];
}

-(void)onScreenCommandTapOnDown:(id)sender {
    // Scroll to bottom
    dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^(void){
        NSInteger rows = [self numberOfRowsInSection:0];
        if (rows) {
            self.quickScrolling = YES;
            [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                        atScrollPosition:UITableViewScrollPositionBottom
                                animated:YES];
            self.quickScrolling = NO;
            // At the end of the previous operation, scroll to bottom again.
            // This ensures the result tableview is indeed at the bottom.
            [[NSOperationQueue currentQueue] addOperationWithBlock:^{
                [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                            atScrollPosition:UITableViewScrollPositionBottom
                                    animated:YES];
            }];
        }
    });
}

#pragma mark - setters
-(void)setDelegate:(id<UITableViewDelegate>)delegate {
    [super setDelegate:delegate];
}

- (void)setLastCellType:(czzThreadViewCommandStatusCellViewType)lastCellType {
    if (_lastCellType != lastCellType) {
        _lastCellType = lastCellType;
        self.lastCellCommandViewController.cellType = lastCellType;
    }
}

#pragma mark - Getters
- (czzThreadViewCommandStatusCellViewController *)lastCellCommandViewController {
    if (!_lastCellCommandViewController) {
        _lastCellCommandViewController = [czzThreadViewCommandStatusCellViewController new];
    }
    return _lastCellCommandViewController;
}
@end
