//
//  czzEmojiCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 9/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzEmojiCollectionViewController.h"
#import "UIViewController+KNSemiModal.h"
#import "czzSettingsCentre.h"

static NSString * const acEmoji = @"acfun_emoji_UTF8";
static NSString * const zhuizhuiEmoji = @"zhuizhui_emoji";

@interface czzEmojiCollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *emojiSelectorSegmentedControl;
@property NSArray *emojis;
@property (nonatomic, strong) NSString *emojiSource;
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
        //self.emojiCollectionView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 44, self.view.frame.size.width, self.view.frame.size.height - 44);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.emojiSource = acEmoji;
    // Do any additional setup after loading the view from its nib.
    [self.emojiCollectionView registerNib:[UINib nibWithNibName:@"czzEmojiCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"emoji_collection_cell_identifier"];
    
    //colours
    emojiPickerToolbar.barTintColor = [settingCentre barTintColour];
    emojiPickerToolbar.tintColor = [settingCentre tintColour];
    emojiCollectionView.backgroundColor = [settingCentre barTintColour];
    
}

#pragma mark - UICollectionView datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.emojis.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"emoji_collection_cell_identifier" forIndexPath:indexPath];
    NSString *emoji = [self.emojis objectAtIndex:indexPath.row];
    if (cell){
        UILabel *emojiLabel = (UILabel*)[cell viewWithTag:1];
        emojiLabel.text = emoji;
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat quarterWidth = MIN(self.view.frame.size.width / 4, 105);
    return CGSizeMake(quarterWidth, 50);
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *emoji = [self.emojis objectAtIndex:indexPath.row];
    [self.delegate emojiSelected:emoji];
}

#pragma mark - UI actions

- (IBAction)cancelAction:(id)sender {
    [self dismissSemiModalView];
}

- (IBAction)selectSourceAction:(id)sender {
    self.emojis = nil;
    if (self.emojiSelectorSegmentedControl.selectedSegmentIndex == 0) {
        self.emojiSource = acEmoji;
    } else {
        self.emojiSource = zhuizhuiEmoji;
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

@end
