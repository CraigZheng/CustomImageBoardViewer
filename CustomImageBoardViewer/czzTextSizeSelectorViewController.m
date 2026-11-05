//
//  czzTextSizeSelectorViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzTextSizeSelectorViewController.h"

@interface czzTextSizeSelectorViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *sizeTitles;
@end

@implementation czzTextSizeSelectorViewController

- (void)loadView {
  UIView *rootView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  rootView.backgroundColor = [UIColor clearColor];
  self.view = rootView;

  UIPickerView *pickerView = [[UIPickerView alloc] init];
  pickerView.translatesAutoresizingMaskIntoConstraints = NO;
  pickerView.backgroundColor = [UIColor systemBackgroundColor];
  pickerView.dataSource = self;
  pickerView.delegate = self;
  [rootView addSubview:pickerView];
  self.pickerView = pickerView;

  UIToolbar *toolbar = [[UIToolbar alloc] init];
  toolbar.translatesAutoresizingMaskIntoConstraints = NO;
  toolbar.items = @[
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    [[UIBarButtonItem alloc] initWithTitle:@"OK" style:UIBarButtonItemStylePlain target:self action:@selector(okButtonAction:)]
  ];
  [rootView addSubview:toolbar];

  [rootView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(tapOnBackgroundViewAction:)]];

  UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [toolbar.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
    [toolbar.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
    [toolbar.heightAnchor constraintEqualToConstant:44],
    [pickerView.topAnchor constraintEqualToAnchor:toolbar.bottomAnchor],
    [pickerView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
    [pickerView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
    [pickerView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]
  ]];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.sizeTitles = @[@"默认", @"偏小", @"偏大", @"特大"];
  [self.pickerView selectRow:settingCentre.threadTextSize inComponent:0 animated:NO];
  
}

#pragma mark - UI actions.
- (IBAction)tapOnBackgroundViewAction:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)okButtonAction:(id)sender {
  if ([self.delegate respondsToSelector:@selector(textSizeSelected:textSize:)]) {
    [self.delegate textSizeSelected:self textSize:[self.pickerView selectedRowInComponent:0]];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPickerViewDelegate & UIPickerViewDataSource

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return self.sizeTitles.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return self.sizeTitles[row];
}

@end
