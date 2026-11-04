//
//  ProgressOverlay.m
//  CustomImageBoardViewer
//

#import "ProgressOverlay.h"

static const NSInteger kProgressOverlayTag = 918273645;

@interface ProgressOverlay ()
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) BOOL determinate;
@end

@implementation ProgressOverlay

+ (instancetype)showInView:(UIView *)view {
    return [self showInView:view determinate:NO];
}

+ (instancetype)showDeterminateInView:(UIView *)view {
    return [self showInView:view determinate:YES];
}

+ (instancetype)showInView:(UIView *)view determinate:(BOOL)determinate {
    [self hideFromView:view animated:NO];
    ProgressOverlay *overlay = [[ProgressOverlay alloc] initWithFrame:view.bounds determinate:determinate];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.tag = kProgressOverlayTag;
    [view addSubview:overlay];
    overlay.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 1;
    }];
    return overlay;
}

+ (void)hideFromView:(UIView *)view animated:(BOOL)animated {
    UIView *existing = [view viewWithTag:kProgressOverlayTag];
    if (![existing isKindOfClass:[ProgressOverlay class]]) {
        return;
    }
    [(ProgressOverlay *)existing hideAnimated:animated];
}

- (instancetype)initWithFrame:(CGRect)frame determinate:(BOOL)determinate {
    self = [super initWithFrame:frame];
    if (self) {
        _determinate = determinate;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];

        _panel = [[UIView alloc] init];
        _panel.translatesAutoresizingMaskIntoConstraints = NO;
        _panel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        _panel.layer.cornerRadius = 12;
        [self addSubview:_panel];

        _statusLabel = [[UILabel alloc] init];
        _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _statusLabel.textColor = [UIColor whiteColor];
        _statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.numberOfLines = 2;
        [_panel addSubview:_statusLabel];

        if (determinate) {
            _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            _progressView.translatesAutoresizingMaskIntoConstraints = NO;
            _progressView.progressTintColor = [UIColor whiteColor];
            _progressView.trackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
            [_panel addSubview:_progressView];
            [NSLayoutConstraint activateConstraints:@[
                [_panel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                [_panel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                [_panel.widthAnchor constraintEqualToConstant:180],
                [_progressView.topAnchor constraintEqualToAnchor:_panel.topAnchor constant:20],
                [_progressView.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:16],
                [_progressView.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-16],
                [_statusLabel.topAnchor constraintEqualToAnchor:_progressView.bottomAnchor constant:12],
                [_statusLabel.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:12],
                [_statusLabel.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-12],
                [_statusLabel.bottomAnchor constraintEqualToAnchor:_panel.bottomAnchor constant:-16]
            ]];
        } else {
            if (@available(iOS 13.0, *)) {
                _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            } else {
                _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            _spinner.translatesAutoresizingMaskIntoConstraints = NO;
            _spinner.color = [UIColor whiteColor];
            [_spinner startAnimating];
            [_panel addSubview:_spinner];
            [NSLayoutConstraint activateConstraints:@[
                [_panel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                [_panel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                [_panel.widthAnchor constraintGreaterThanOrEqualToConstant:100],
                [_panel.heightAnchor constraintGreaterThanOrEqualToConstant:100],
                [_spinner.centerXAnchor constraintEqualToAnchor:_panel.centerXAnchor],
                [_spinner.centerYAnchor constraintEqualToAnchor:_panel.centerYAnchor],
                [_statusLabel.topAnchor constraintEqualToAnchor:_spinner.bottomAnchor constant:8],
                [_statusLabel.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:12],
                [_statusLabel.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-12],
                [_statusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:_panel.bottomAnchor constant:-12]
            ]];
        }
    }
    return self;
}

- (void)setProgress:(float)progress {
    _progress = progress;
    self.progressView.progress = progress;
}

- (void)setStatusText:(NSString *)statusText {
    _statusText = [statusText copy];
    self.statusLabel.text = statusText;
}

- (void)hideAnimated:(BOOL)animated {
    void (^remove)(void) = ^{
        [self removeFromSuperview];
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            remove();
        }];
    } else {
        remove();
    }
}

@end
