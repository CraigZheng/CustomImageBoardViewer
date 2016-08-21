//
//  czzTextSizeSelectorViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzTextSizeSelectorViewController.h"

@interface czzTextSizeSelectorViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *sizeTitles;
@end

@implementation czzTextSizeSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sizeTitles = @[@"默认", @"偏大", @"偏小"];
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
    return 3;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.sizeTitles[row];
}

@end
