//
//  czzThreadViewCommandStatusCellViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadViewCommandStatusCellViewController.h"
#import "PureLayout.h"
#import "czzSettingsCentre.h"

@interface czzThreadViewCommandStatusCellViewController ()
@property (weak, nonatomic) IBOutlet UILabel *commandStatusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (assign, nonatomic) BOOL up;
@end

@implementation czzThreadViewCommandStatusCellViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
    
    [self renderContent];
}

- (void)renderContent {
    @try {
        self.view.backgroundColor = [settingCentre viewBackgroundColour];
        NSString *commandLabelString;
        [self.loadingActivityIndicator stopAnimating];
        switch (self.cellType) {
            case czzThreadViewCommandStatusCellViewTypeLoadMore:
                commandLabelString = @"点击以加载";
                self.up = NO;
                break;
            case czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore:
                commandLabelString = @"松开以加载";
                self.up = YES;
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
    @catch (NSException *exception) {
        DDLogDebug(@"%@",exception);
    }
}

// Flash the content view, grab user's attention.
-(void)flash {
    UIView *orangeOverlayView = [UIView new];
    orangeOverlayView.backgroundColor = [UIColor orangeColor];
    orangeOverlayView.alpha = 0.5;
    [self.view addSubview:orangeOverlayView];
    [orangeOverlayView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [UIView animateWithDuration:0.2 animations:^{
            orangeOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            [orangeOverlayView removeFromSuperview];
        }];
    }];
}

#pragma mark - Setters
- (void)setCellType:(czzThreadViewCommandStatusCellViewType)cellType {
    if (_cellType != cellType) {
        _cellType = cellType;
    }
    [self renderContent];
}

// If value changed, flash once.
- (void)setUp:(BOOL)up {
    if (_up != up) {
        [self flash];
    }
    _up = up;
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"czzThreadTableViewCommandStatusCellViewController" bundle:nil] instantiateInitialViewController];
}
@end
