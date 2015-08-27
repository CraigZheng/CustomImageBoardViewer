//
//  czzThreadTableView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableView.h"

#import "czzMenuEnabledTableViewCell.h"
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
}

-(void)registerNibs {
    // Register thread view cells
    [self registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    [self registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    // Register thread view command cells
    [self registerNib:[UINib nibWithNibName:THREAD_TABLEVIEW_COMMAND_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER];
}

- (void)reloadData {
    [super reloadData];
}

-(void)scrollToTop {
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [self setContentOffset:CGPointMake(0, -self.contentInset.top) animated:NO];
    }];
}

#pragma mark - czzOnScreenCommandViewControllerDelegate
-(void)onScreenCommandTapOnUp:(id)sender {
    // Scroll to top
    [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                atScrollPosition:UITableViewScrollPositionTop
                        animated:YES];
}

-(void)onScreenCommandTapOnDown:(id)sender {
    // Scroll to bottom
    if ([self numberOfRowsInSection:0] > 0) {
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self numberOfRowsInSection:0] - 1 inSection:0]
                    atScrollPosition:UITableViewScrollPositionBottom
                            animated:YES];
    }
}

#pragma mark - setters
-(void)setDelegate:(id<UITableViewDelegate>)delegate {
    [super setDelegate:delegate];
}
@end
