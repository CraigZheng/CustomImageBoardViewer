//
//  czzThreadViewCommandStatusCellViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadViewCommandStatusCellViewController.h"

@interface czzThreadViewCommandStatusCellViewController ()
@property (weak, nonatomic) IBOutlet UILabel *commandStatusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;

@end

@implementation czzThreadViewCommandStatusCellViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
    
    [self renderContent];
}

- (void)renderContent {
    @try {
        if (self.isPresented) {
            self.view.backgroundColor = [settingCentre viewBackgroundColour];
            NSString *commandLabelString;
            [self.loadingActivityIndicator stopAnimating];
            switch (self.cellType) {
                case czzThreadViewCommandStatusCellViewTypeLoadMore:
                    commandLabelString = @"点击以加载";
                    break;
                case czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore:
                    commandLabelString = @"松开以加载";
                    break;
                case czzThreadViewCommandStatusCellViewTypeNoMore:
                    commandLabelString = @"没有更多内容，点击以加载";
                    break;
                case czzThreadViewCommandStatusCellViewTypeLoading:
                    commandLabelString = @"加载中...";
                    [self.loadingActivityIndicator startAnimating];
                    break;
                default:
                    break;
            }
            self.commandStatusLabel.text = commandLabelString;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@",exception);
    }
}

#pragma mark - Setters
- (void)setCellType:(czzThreadViewCommandStatusCellViewType)cellType {
    if (_cellType != cellType) {
        _cellType = cellType;
    }
    [self renderContent];
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"czzThreadTableViewCommandStatusCellViewController" bundle:nil] instantiateInitialViewController];
}
@end
