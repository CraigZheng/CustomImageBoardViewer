//
//  czzEmojiCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 9/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzEmojiCollectionViewController.h"
#import "UIViewController+KNSemiModal.h"

@interface czzEmojiCollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property NSArray *emojis;
@end

@implementation czzEmojiCollectionViewController
@synthesize emojis;
@synthesize emojiCollectionView;

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
    // Do any additional setup after loading the view from its nib.
    emojis = [self readyEmoji];
    [self.emojiCollectionView registerNib:[UINib nibWithNibName:@"czzEmojiCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"emoji_collection_cell_identifier"];
    
}

#pragma mark - UICollectionView datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return emojis.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"emoji_collection_cell_identifier" forIndexPath:indexPath];
    NSString *emoji = [emojis objectAtIndex:indexPath.row];
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
    NSString *emoji = [emojis objectAtIndex:indexPath.row];
    [self.delegate emojiSelected:emoji];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissSemiModalView];
}

-(NSArray*)readyEmoji{
    NSMutableArray *tempEmojis = [NSMutableArray new];
    NSString *emojiFile = [[NSBundle mainBundle] pathForResource:@"acfun_emoji_UTF8" ofType:@"txt"];
    NSError *error;
    NSString *emojiFileContent = [NSString stringWithContentsOfFile:emojiFile encoding:NSUTF8StringEncoding error:&error];
    if (error){
        DLog(@"%@", error);
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
@end
