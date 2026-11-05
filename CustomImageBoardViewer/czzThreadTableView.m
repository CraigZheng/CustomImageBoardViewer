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

#import "CustomImageBoardViewer-Swift.h"

@interface czzThreadTableView () <czzOnScreenCommandViewControllerDelegate>

@end

@implementation czzThreadTableView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self registerNibs];
        [self configureCommandOverlay];
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
    [super awakeFromNib];
    [self configureCommandOverlay];
}

-(void)configureCommandOverlay {
    self.upDownViewController = [czzOnScreenCommandViewController new];
    self.upDownViewController.delegate = self;
    self.estimatedRowHeight = 44.0;
    self.rowHeight = UITableViewAutomaticDimension;
}

- (void)registerNibs {
    [self registerCellClasses];
}

/// Registers every cell type this table can dequeue. Cells are built in code, so
/// the table never needs a nib.
- (void)registerCellClasses {
    [self registerClass:[czzMenuEnabledTableViewCell class] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    // The big image cell still comes from its nib until it is built in code.
    [self registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_VIEW_CELL_NIB_NAME bundle:nil]
        forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    [self registerClass:[czzThreadTableViewCommandCellTableViewCell class] forCellReuseIdentifier:THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER];
}

- (void)reloadData {
    [super reloadData];
}

-(void)scrollToTop:(BOOL)animated {
    self.quickScrolling = YES;
    @try {
        if ([self numberOfSections] > 0 && [self numberOfRowsInSection:0]) {
            [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                        atScrollPosition:UITableViewScrollPositionTop
                                animated:animated];
        }
    } @catch (NSException *exception) {
        [self setContentOffset:CGPointMake(0, -self.contentInset.top) animated:animated];
    }
    self.quickScrolling = NO;
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
            [self scrollToRowAtIndexPath:self.lastIndexPath
                        atScrollPosition:UITableViewScrollPositionBottom
                                animated:YES];
            self.quickScrolling = NO;
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
