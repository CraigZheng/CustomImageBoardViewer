//
//  czzShortImageManagerCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzShortImageManagerCollectionViewController.h"
#import "UIView+MGBadgeView.h"
#import "czzAppDelegate.h"
#import "czzImageCentre.h"
#import "czzImageDownloader.h"
#import "KLCPopup.h"

@interface czzShortImageManagerCollectionViewController ()<czzImageCentreProtocol>
@property czzImageCentre *imageCentre;
@property NSArray *downloaders;
@property KLCPopup *popup;
@end

@implementation czzShortImageManagerCollectionViewController
@synthesize delegate;
@synthesize imageCentre;
@synthesize downloaders;
@synthesize popup;
@synthesize managerCollectionView;
@synthesize isShowing;
@synthesize downloadedImages;

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";
static NSString *downloadedImageCellIdentifier = @"downloaded_image_view_cell";

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [managerCollectionView reloadData];
}

- (IBAction)tapOnViewAction:(id)sender {
    isShowing = NO;
    [popup dismiss:YES];
}

-(void)show {
    imageCentre = [czzImageCentre sharedInstance];
    downloaders = imageCentre.currentImageDownloaders.array;

    if (downloaders.count <= 0 && downloadedImages.count <= 0)
    {
        DLog(@"No image in progress, return...");
        return;
    }
    popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    
    [popup showWithLayout:KLCPopupLayoutCenter];
    
    isShowing = YES;
}

-(void)updateProgressForDownloader:(czzImageDownloader *)downloader {
    [managerCollectionView reloadData];
}

-(void)imageDownloaded:(NSString *)imgPath {
    if (!downloadedImages)
        downloadedImages = [NSMutableArray new];
    [downloadedImages addObject:imgPath];
    [managerCollectionView reloadData];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0)
        return downloaders.count;
    return downloadedImages.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];
        
        UIImageView *downloaderThumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        UILabel *downloaderLabel = (UILabel*) [cell viewWithTag:2];
        czzImageDownloader *currentDownloader = [downloaders objectAtIndex:indexPath.row];
        //thumbnail
        UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:[[currentDownloader targetURLString] lastPathComponent]]];
        if (thumbnailImage) {
            downloaderThumbnailImageView.image = thumbnailImage;
        } else {
            downloaderThumbnailImageView.image = [UIImage imageNamed:@"icon.png"];
        }
        //progress label
        NSString *progressText = [NSString stringWithFormat:@"%.1f%%", [currentDownloader progress] * 100];
        downloaderLabel.text = progressText;
        return cell;
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:downloadedImageCellIdentifier forIndexPath:indexPath];
        
        UIImageView *thumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        NSString *imgPath = [downloadedImages objectAtIndex:indexPath.row];
        UIImage *fullImg = [UIImage imageWithContentsOfFile:imgPath];
        UIImage *thumbnailImg = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:imgPath.lastPathComponent]];
        
        thumbnailImageView.image = thumbnailImg ? thumbnailImg : fullImg;
        
        return cell;
    }
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        czzImageDownloader *imgDownloader = [downloaders objectAtIndex:indexPath.row];
        [imageCentre stopAndRemoveImageDownloaderWithURL:imgDownloader.imageURLString];
        DLog(@"stop downloading: %@", imgDownloader.imageURLString);
    }
    else {
        NSString *imgPath = [downloadedImages objectAtIndex:indexPath.row];
        if (delegate && [delegate respondsToSelector:@selector(userTappedOnImageWithPath:)]) {
            [delegate userTappedOnImageWithPath:imgPath];
        }
    }
}
@end
