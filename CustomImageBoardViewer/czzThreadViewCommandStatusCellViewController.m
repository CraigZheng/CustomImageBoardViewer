//
//  czzThreadViewCommandStatusCellViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadViewCommandStatusCellViewController.h"
#import "czzSettingsCentre.h"
#import "czzThreadViewManager.h"
#import "CPAutoFillView.h"
#import "CustomImageBoardViewer-Swift.h"

@interface NSObject (czzLoadPreviousPageAction)
- (void)tappedOnLoadPreviousPage:(id)sender;
@end

@interface czzThreadViewCommandStatusCellViewController ()
@property (strong, nonatomic) UIButton *commandButton;
@property (strong, nonatomic) UIActivityIndicatorView *loadingActivityIndicator;
@property (assign, nonatomic) BOOL up;
@end

@implementation czzThreadViewCommandStatusCellViewController

- (void)loadView {
    CPAutoFillView *autoFillView = [[CPAutoFillView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    autoFillView.backgroundColor = [UIColor whiteColor];
    self.view = autoFillView;
    
    _loadingActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _loadingActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _loadingActivityIndicator.hidesWhenStopped = YES;
    [_loadingActivityIndicator stopAnimating];
    [self.view addSubview:_loadingActivityIndicator];
    
    _commandButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _commandButton.translatesAutoresizingMaskIntoConstraints = NO;
    _commandButton.enabled = NO;
    _commandButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.678 blue:0.173 alpha:1.0];
    [_commandButton setTitleColor:[UIColor colorWithWhite:0.333 alpha:1.0] forState:UIControlStateNormal];
    _commandButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _commandButton.layer.cornerRadius = 4.0;
    _commandButton.clipsToBounds = YES;
    [_commandButton addTarget:nil action:@selector(tappedOnLoadPreviousPage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_commandButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [_loadingActivityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_loadingActivityIndicator.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        
        [_commandButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_commandButton.heightAnchor constraintEqualToConstant:28],
        [_commandButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [_commandButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40]
    ]];
}

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
        NSString *pageString = @"";
        if ([self.homeViewManager isMemberOfClass:[czzThreadViewManager class]]) {
            pageString = [NSString stringWithFormat:@" - 第%ld/%ld页", (long)self.homeViewManager.threads.lastObject.pageNumber ?: 1, (long)self.homeViewManager.totalPages ?: 1];
        }
        switch (self.cellType) {
            case czzThreadViewCommandStatusCellViewTypeLoadMore:
                commandLabelString = [NSString stringWithFormat:@"%@%@", @"点击以加载", pageString];
                self.up = NO;
                break;
            case czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore:
                commandLabelString = [NSString stringWithFormat:@"%@%@", @"松开以加载", pageString];
                self.up = YES;
                break;
            case czzThreadViewCommandStatusCellViewTypeNoMore:
                commandLabelString = [NSString stringWithFormat:@"%@%@", @"没有更多内容，点击以加载", pageString];
                break;
            case czzThreadViewCommandStatusCellViewTypeLoading:
                commandLabelString = [NSString stringWithFormat:@"%@%@", @"加载中", pageString];
                break;
            default:
                break;
        }
        [self.commandButton setTitle:commandLabelString forState:UIControlStateNormal];
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@",exception);
    }
}

// Flash the content view, grab user's attention.
- (void)flash {
    UIView *orangeOverlayView = [UIView new];
    orangeOverlayView.backgroundColor = [UIColor orangeColor];
    orangeOverlayView.alpha = 0.5;
    [self.view addSubview:orangeOverlayView];
    orangeOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [orangeOverlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [orangeOverlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [orangeOverlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [orangeOverlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    
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
    return [[self alloc] init];
}

@end
