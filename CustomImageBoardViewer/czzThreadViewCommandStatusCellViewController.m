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
            NSString *commandLabelString;
            [self.loadingActivityIndicator stopAnimating];
            switch (self.cellType) {
                case czzThreadViewCommandStatusCellViewTypeLoadMore:
                    commandLabelString = @"Tap To Load More";
                    break;
                case czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore:
                    commandLabelString = @"Release To Load More";
                    break;
                case czzThreadViewCommandStatusCellViewTypeNoMore:
                    commandLabelString = @"No More Content, Tap To Refresh";
                    break;
                case czzThreadViewCommandStatusCellViewTypeLoading:
                    commandLabelString = @"Loading, Please Wait";
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
