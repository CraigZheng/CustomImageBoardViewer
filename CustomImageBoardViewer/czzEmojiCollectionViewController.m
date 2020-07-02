//
//  czzEmojiCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 9/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzEmojiCollectionViewController.h"
#import "czzSettingsCentre.h"
#import "CustomImageBoardViewer-Swift.h"

static NSString * const acEmoji = @"acfun_emoji_UTF8";
static NSString * const zhuizhuiEmoji = @"zhuizhui_emoji";

static NSString * const emojiCellIdentifier = @"emoji_collection_cell_identifier";
static NSString * const emoticonCellIdentifier = @"emoticon_collection_view_cell";

static NSInteger const emoticonSegmentedControlIndex = 2;

@interface czzEmojiCollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching>
@property (weak, nonatomic) IBOutlet UIToolbar *emoPackPickerToolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emoPackPickerToolbarHeightConstraint;
@property (weak, nonatomic) IBOutlet UISegmentedControl *emojiSelectorSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *emoPackPickerSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *darkenView;
@property (nonatomic, strong) NSArray<NSString *> *emojis;
@property (nonatomic, strong) NSString *emojiSource;
@property (nonatomic, strong) NSArray<NSString *> *emoPack;
@property (nonatomic, strong) NSArray<NSString *> *classicAC;
@property (nonatomic, strong) NSArray<NSString *> *neoAC;
@property (nonatomic, strong) NSArray<NSString *> *reedColor;
@property (nonatomic, strong) NSArray<NSString *> *reedGirl;
@end

@implementation czzEmojiCollectionViewController
@synthesize emojiCollectionView;
@synthesize emojiPickerToolbar;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
            self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 1.5);
        } else {
            self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width / 2.0);
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.emoPackPickerToolbar.hidden = YES;
    self.emoPackPickerToolbarHeightConstraint.constant = 0;
    [self.emojiCollectionView registerNib:[UINib nibWithNibName:@"czzEmojiCollectionViewCell" bundle:[NSBundle mainBundle]]
               forCellWithReuseIdentifier:emojiCellIdentifier];
    [self.emojiCollectionView registerNib:[UINib nibWithNibName:@"EmoticonCollectionViewCell" bundle:[NSBundle mainBundle]]
               forCellWithReuseIdentifier:emoticonCellIdentifier];
    
    //colours
    self.emoPackPickerToolbar.barTintColor = emojiPickerToolbar.barTintColor = [settingCentre barTintColour];
    self.emoPackPickerToolbar.tintColor = emojiPickerToolbar.tintColor = [settingCentre tintColour];
    emojiCollectionView.backgroundColor = [settingCentre barTintColour];
    [self.emojiSelectorSegmentedControl setEnabled:settingCentre.shouldShowEmoPackPicker forSegmentAtIndex:2];
    [self emoPackSelectionChanged:nil];
    self.emojiSource = acEmoji;
    if ([self.emojiCollectionView respondsToSelector:@selector(prefetchDataSource)]) {
        self.emojiCollectionView.prefetchDataSource = self;
    }
}

#pragma mark - UICollectionView datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex ? self.emoPack.count : self.emojis.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:emoticonCellIdentifier forIndexPath:indexPath];
        if ([cell isKindOfClass:[EmoticonCollectionViewCell class]]) {
            [[(EmoticonCollectionViewCell *)cell iconView] setImage:[UIImage imageNamed:self.emoPack[indexPath.row]]];
        }
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:emojiCellIdentifier forIndexPath:indexPath];
        NSString *emoji = [self.emojis objectAtIndex:indexPath.row];
        if (cell){
            UILabel *emojiLabel = (UILabel*)[cell viewWithTag:1];
            emojiLabel.text = emoji;
        }
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat quarterWidth = MIN(self.view.frame.size.width / 4, 105);
    return CGSizeMake(quarterWidth, 60);
}

#pragma mark - UICollectionViewPrefetching
- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex) {
        for (NSIndexPath *indexPath in indexPaths) {
            [UIImage imageNamed:self.emoPack[indexPath.row]];
        }
    }
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex) {
        // Emoticon selection.
        if (indexPath.row <= self.emoPack.count) {
            [self.delegate emoticonSelected:[UIImage imageNamed:self.emoPack[indexPath.row]]];
        }
    } else {
        // Emoji selection.
        NSString *emoji = [self.emojis objectAtIndex:indexPath.row];
        [self.delegate emojiSelected:emoji];
    }
}

#pragma mark - UI actions

- (IBAction)emoPackSelectionChanged:(id)sender {
    switch (self.emoPackPickerSegmentedControl.selectedSegmentIndex) {
        case 0:
            self.emoPack = self.reedGirl;
            break;
        case 1:
            self.emoPack = self.classicAC;
            break;
        case 2:
            self.emoPack = self.neoAC;
            break;
        case 3:
            self.emoPack = self.reedColor;
            break;
        default:
            self.emoPack = self.reedGirl;
            break;
    }
    [self.emojiCollectionView reloadData];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)selectSourceAction:(id)sender {
    self.emojis = nil;
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == 0) {
        self.emojiSource = acEmoji;
    } else if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == 1) {
        self.emojiSource = zhuizhuiEmoji;
    }
    BOOL isEmoticonSelected = self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex;
    if (isEmoticonSelected) {
        self.emoPackPickerToolbarHeightConstraint.constant = 44;
        self.emoPackPickerToolbar.hidden = NO;
        self.darkenView.hidden = ![settingCentre userDefNightyMode];
    } else {
        self.emoPackPickerToolbarHeightConstraint.constant = 0;
        self.emoPackPickerToolbar.hidden = YES;
        self.darkenView.hidden = YES;
    }
    [emojiCollectionView reloadData];
}

-(NSArray*)readyEmoji{
    NSMutableArray *tempEmojis = [NSMutableArray new];
    NSString *emojiFile = [[NSBundle mainBundle] pathForResource:self.emojiSource ofType:@"txt"];
    NSError *error;
    NSString *emojiFileContent = [NSString stringWithContentsOfFile:emojiFile encoding:NSUTF8StringEncoding error:&error];
    if (error){
        DDLogDebug(@"%@", error);
    }
    NSArray *lines;
    lines = [emojiFileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        /*
        NSRange range = [line rangeOfString:@"="];
        if (range.location != NSNotFound) {
            NSString *emoji = [line substringFromIndex:range.location + range.length];
            [tempEmojis addObject:emoji];
        }
         */
        if (line.length != 0)
            [tempEmojis addObject:line];
    }
    
    return tempEmojis;
}

#pragma mark - Getters

- (NSArray *)emojis {
    if (!_emojis) {
        _emojis = [self readyEmoji];
    }
    return _emojis;
}

- (NSArray<NSString *> *)classicAC {
    if (!_classicAC) {
        _classicAC = [self emoPackWithFormat:@"ac-classic%ld.png" quantity:54];
    }
    return _classicAC;
}

- (NSArray<NSString *> *)neoAC {
    if (!_neoAC) {
        _neoAC = [self emoPackWithFormat:@"ac-new%ld.png" quantity:95];
    }
    return _neoAC;
}

- (NSArray<NSString *> *)reedColor {
    if (!_reedColor) {
        _reedColor = [self emoPackWithFormat:@"reed-color%ld.png" quantity:105];
    }
    return _reedColor;
}

- (NSArray<NSString *> *)reedGirl {
    if (!_reedGirl) {
        _reedGirl = [self emoPackWithFormat:@"reed-classic%ld.png" quantity:106];
    }
    return _reedGirl;
}

- (NSArray<NSString *> *)emoPackWithFormat:(NSString *)format quantity:(NSInteger)quantity {
    NSMutableArray *imageNames = [NSMutableArray new];
    for (NSInteger i = 1; i <= quantity; i++) {
        NSString *name = [NSString stringWithFormat:format, (long)i];
        if (name) {
            [imageNames addObject:name];
        }
    }
    return imageNames;
}

@end
