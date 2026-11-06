//
//  czzEmojiCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 9/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzEmojiCollectionViewController.h"
#import "czzEmojiCollectionViewCell.h"
#import "czzSettingsCentre.h"
#import "CustomImageBoardViewer-Swift.h"

static NSString * const acEmoji = @"acfun_emoji_UTF8";
static NSString * const zhuizhuiEmoji = @"zhuizhui_emoji";

static NSString * const emojiCellIdentifier = @"emoji_collection_cell_identifier";
static NSString * const emoticonCellIdentifier = @"emoticon_collection_view_cell";

static NSInteger const emoticonSegmentedControlIndex = 2;

static CGFloat const toolbarHeight = 44;
static CGFloat const emojiCellHeight = 60;
static CGFloat const emojiCellMaximumWidth = 105;
static CGFloat const darkenViewAlpha = 0.20467177013422819;

@interface czzEmojiCollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching>
@property (nonatomic, strong) UIToolbar *emojiPickerToolbar;
@property (nonatomic, strong) UISegmentedControl *emojiSelectorSegmentedControl;
@property (nonatomic, strong) UIToolbar *emoPackPickerToolbar;
@property (nonatomic, strong) UISegmentedControl *emoPackPickerSegmentedControl;
@property (nonatomic, strong) NSLayoutConstraint *emoPackPickerToolbarHeightConstraint;
@property (nonatomic, strong) UIView *darkenView;
@property (nonatomic, strong) NSArray<NSString *> *emojis;
@property (nonatomic, strong) NSString *emojiSource;
@property (nonatomic, strong) NSArray<NSString *> *emoPack;
@property (nonatomic, strong) NSArray<NSString *> *classicAC;
@property (nonatomic, strong) NSArray<NSString *> *neoAC;
@property (nonatomic, strong) NSArray<NSString *> *reedColor;
@property (nonatomic, strong) NSArray<NSString *> *reedGirl;
@end

@implementation czzEmojiCollectionViewController
@synthesize emojiCollectionView = _emojiCollectionView;

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

- (void)loadView {
    UIView *rootView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    rootView.backgroundColor = [UIColor whiteColor];
    self.view = rootView;

    // The emoji source picker sits at the top, the emo pack picker appears directly below it
    // only while the emoticon source is selected, and the collection view fills the rest.
    UIStackView *toolbarStackView = [[UIStackView alloc] init];
    toolbarStackView.translatesAutoresizingMaskIntoConstraints = NO;
    toolbarStackView.axis = UILayoutConstraintAxisVertical;
    toolbarStackView.spacing = 0;
    [rootView addSubview:toolbarStackView];

    self.emojiPickerToolbar = [self toolbar];
    [self.emojiPickerToolbar.heightAnchor constraintEqualToConstant:toolbarHeight].active = YES;
    self.emoPackPickerToolbar = [self toolbar];
    [toolbarStackView addArrangedSubview:self.emojiPickerToolbar];
    [toolbarStackView addArrangedSubview:self.emoPackPickerToolbar];

    self.emoPackPickerToolbarHeightConstraint = [self.emoPackPickerToolbar.heightAnchor constraintEqualToConstant:toolbarHeight];

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 2;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeMake(emojiCellMaximumWidth, emojiCellHeight);

    _emojiCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _emojiCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _emojiCollectionView.backgroundColor = [UIColor whiteColor];
    _emojiCollectionView.dataSource = self;
    _emojiCollectionView.delegate = self;
    [rootView addSubview:_emojiCollectionView];

    self.darkenView = [[UIView alloc] init];
    self.darkenView.translatesAutoresizingMaskIntoConstraints = NO;
    self.darkenView.backgroundColor = [UIColor colorWithWhite:0 alpha:darkenViewAlpha];
    self.darkenView.userInteractionEnabled = NO;
    self.darkenView.hidden = YES;
    [rootView addSubview:self.darkenView];

    UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [toolbarStackView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [toolbarStackView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [toolbarStackView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        self.emoPackPickerToolbarHeightConstraint,

        [_emojiCollectionView.topAnchor constraintEqualToAnchor:toolbarStackView.bottomAnchor],
        [_emojiCollectionView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [_emojiCollectionView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [_emojiCollectionView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],

        [self.darkenView.topAnchor constraintEqualToAnchor:_emojiCollectionView.topAnchor],
        [self.darkenView.leadingAnchor constraintEqualToAnchor:_emojiCollectionView.leadingAnchor],
        [self.darkenView.trailingAnchor constraintEqualToAnchor:_emojiCollectionView.trailingAnchor],
        [self.darkenView.bottomAnchor constraintEqualToAnchor:_emojiCollectionView.bottomAnchor]
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.emoPackPickerToolbar.hidden = YES;
    self.emoPackPickerToolbarHeightConstraint.constant = 0;
    [self.emojiCollectionView registerClass:[czzEmojiCollectionViewCell class]
                 forCellWithReuseIdentifier:emojiCellIdentifier];
    [self.emojiCollectionView registerClass:[czzEmoticonCollectionViewCell class]
                 forCellWithReuseIdentifier:emoticonCellIdentifier];

    //colours
    self.emoPackPickerToolbar.backgroundColor = self.emoPackPickerToolbar.barTintColor = self.emojiPickerToolbar.barTintColor = [settingCentre barTintColour];
    self.emoPackPickerToolbar.tintColor = self.emojiPickerToolbar.tintColor = [settingCentre tintColour];
    self.emojiCollectionView.backgroundColor = [settingCentre barTintColour];
    [self.emojiSelectorSegmentedControl setEnabled:settingCentre.shouldShowEmoPackPicker forSegmentAtIndex:emoticonSegmentedControlIndex];
    [self emoPackSelectionChanged:nil];
    self.emojiSource = acEmoji;
    if ([self.emojiCollectionView respondsToSelector:@selector(prefetchDataSource)]) {
        self.emojiCollectionView.prefetchDataSource = self;
    }
}

#pragma mark - View factory

- (UIToolbar *)toolbar {
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    return toolbar;
}

- (UISegmentedControl *)emojiSelectorSegmentedControl {
    if (!_emojiSelectorSegmentedControl) {
        _emojiSelectorSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"表情包"]];
        _emojiSelectorSegmentedControl.selectedSegmentIndex = 0;
        [_emojiSelectorSegmentedControl addTarget:self action:@selector(selectSourceAction:) forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem *segmentItem = [[UIBarButtonItem alloc] initWithCustomView:_emojiSelectorSegmentedControl];
        self.emojiPickerToolbar.items = @[
            [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete.png"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            segmentItem
        ];
    }
    return _emojiSelectorSegmentedControl;
}

- (UISegmentedControl *)emoPackPickerSegmentedControl {
    if (!_emoPackPickerSegmentedControl) {
        _emoPackPickerSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"芦苇娘", @"经典AC娘", @"新AC娘", @"彩色芦苇"]];
        _emoPackPickerSegmentedControl.selectedSegmentIndex = 3;
        [_emoPackPickerSegmentedControl addTarget:self action:@selector(emoPackSelectionChanged:) forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem *segmentItem = [[UIBarButtonItem alloc] initWithCustomView:_emoPackPickerSegmentedControl];
        self.emoPackPickerToolbar.items = @[
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            segmentItem
        ];
    }
    return _emoPackPickerSegmentedControl;
}

#pragma mark - UICollectionView datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex ? self.emoPack.count : self.emojis.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell;
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:emoticonCellIdentifier forIndexPath:indexPath];
        if ([cell isKindOfClass:[czzEmoticonCollectionViewCell class]] && indexPath.row < self.emoPack.count) {
            [[(czzEmoticonCollectionViewCell *)cell iconView] setImage:[UIImage imageNamed:self.emoPack[indexPath.row]]];
        }
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:emojiCellIdentifier forIndexPath:indexPath];
        if ([cell isKindOfClass:[czzEmojiCollectionViewCell class]] && indexPath.row < self.emojis.count) {
            [(czzEmojiCollectionViewCell *)cell emojiLabel].text = [self.emojis objectAtIndex:indexPath.row];
        }
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat quarterWidth = MIN(self.view.frame.size.width / 4, emojiCellMaximumWidth);
    return CGSizeMake(quarterWidth, emojiCellHeight);
}

#pragma mark - UICollectionViewPrefetching
- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex) {
        for (NSIndexPath *indexPath in indexPaths) {
            if (indexPath.row < self.emoPack.count) {
                [UIImage imageNamed:self.emoPack[indexPath.row]];
            }
        }
    }
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == emoticonSegmentedControlIndex) {
        // Emoticon selection. A row equal to count is out of range, so this must
        // be a strict comparison.
        if (indexPath.row < self.emoPack.count) {
            [self.delegate emoticonSelected:[UIImage imageNamed:self.emoPack[indexPath.row]]];
        }
    } else {
        // Emoji selection. Guard the index: the delegate can be called with a row
        // that no longer exists after the source changes.
        if (indexPath.row < self.emojis.count) {
            [self.delegate emojiSelected:[self.emojis objectAtIndex:indexPath.row]];
        }
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
        self.emoPackPickerToolbarHeightConstraint.constant = toolbarHeight;
        self.emoPackPickerToolbar.hidden = NO;
        self.darkenView.hidden = ![settingCentre userDefNightyMode];
    } else {
        self.emoPackPickerToolbarHeightConstraint.constant = 0;
        self.emoPackPickerToolbar.hidden = YES;
        self.darkenView.hidden = YES;
    }
    [self.emojiCollectionView reloadData];
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
