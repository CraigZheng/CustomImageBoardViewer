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

-(void)registerNibs {
    // Register thread view cells
    [self registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    [self registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    // Register thread view command cells
    [self registerNib:[UINib nibWithNibName:THREAD_TABLE_VIEW_CELL_LOAD_MORE_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_TABLE_VIEW_CELL_LOAD_MORE_CELL_IDENTIFIER];
    [self registerNib:[UINib nibWithNibName:THREAD_TABLE_VIEW_CELL_LOADING_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_TABLE_VIEW_CELL_LOADING_CELL_IDENTIFIER];
    [self registerNib:[UINib nibWithNibName:THREAD_TABLE_VIEW_CELL_NO_MORE_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_TABLE_VIEW_CELL_NO_MORE_CELL_IDENTIFIER];
}

@end
