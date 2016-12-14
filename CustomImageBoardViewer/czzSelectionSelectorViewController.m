//
//  czzSelectionSelectorViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzSelectionSelectorViewController.h"

@interface czzSelectionSelectorViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@end

@implementation czzSelectionSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.pickerView selectRow:settingCentre.threadTextSize inComponent:0 animated:NO];

}

#pragma mark - UI actions.
- (IBAction)tapOnBackgroundViewAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)okButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(selectorViewController:selectedIndex:)]) {
        [self.delegate selectorViewController:self selectedIndex:[self.pickerView selectedRowInComponent:0]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPickerViewDelegate & UIPickerViewDataSource

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.selections.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.selections[row];
}

@end
