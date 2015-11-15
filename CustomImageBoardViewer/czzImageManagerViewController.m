//
//  czzImageManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageManagerViewController.h"
#import "czzImageCacheManager.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "czzImageViewerUtil.h"

#define FULL_SIZE_IMAGE 0
#define THUMBNAIL 1
#define ALL_IMAGE 2

@interface czzImageManagerViewController ()
@property NSMutableArray<NSURL *> *Images;
@property NSInteger imageCategory;
@property czzImageViewerUtil *imageViewerUtil;
@end

@implementation czzImageManagerViewController
@synthesize Images;
@synthesize gallarySegmentControl;
@synthesize imageCategory;
@synthesize imageViewerUtil;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    imageViewerUtil = [czzImageViewerUtil new];
    // Show all images.
    imageCategory = FULL_SIZE_IMAGE;
    [self reloadImageFiles];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

#pragma Load data from image centre
-(void)reloadImageFiles{
    Images = [NSMutableArray new];
    if (imageCategory == ALL_IMAGE){
        [Images addObjectsFromArray:[[czzImageCacheManager sharedInstance] thumbnailImages]];
        [Images addObjectsFromArray:[[czzImageCacheManager sharedInstance] fullsizeImages]];
    } else if (imageCategory == FULL_SIZE_IMAGE) {
        [Images addObjectsFromArray:[[czzImageCacheManager sharedInstance] fullsizeImages]];
    } else if (imageCategory == THUMBNAIL){
        [Images addObjectsFromArray:[[czzImageCacheManager sharedInstance] thumbnailImages]];
    }
    [self.collectionView reloadData];
}


#pragma UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return Images.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"preview_image_cell_identifier" forIndexPath:indexPath];
    NSURL *imageFileURL = [Images objectAtIndex:indexPath.row];
    if (cell && imageFileURL){
        UIImageView *previewImageView = (UIImageView*)[cell viewWithTag:1];
        NSString *imageName = imageFileURL.lastPathComponent;
        UIImage *previewImage = [UIImage imageWithData:
                                 [NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] hasThumbnailWithName:imageName] ?
                                  [[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName] :
                                  [[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
        
        if (previewImage) {
            previewImageView.image = previewImage;
        } else {
            previewImageView.image = [UIImage imageNamed:@"icon.png"];
        }
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat quaterWidth = self.view.frame.size.width / 4;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        quaterWidth = self.view.frame.size.width / 6;
    return CGSizeMake(quaterWidth, quaterWidth);
}

#pragma UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [imageViewerUtil showPhotos:Images withIndex:indexPath.row];
}

//show different categories of images
- (IBAction)gallarySegmentControlAction:(id)sender {
    UISegmentedControl *control = (UISegmentedControl*)sender;
    imageCategory = control.selectedSegmentIndex;
    [self reloadImageFiles];
}

#pragma mark memory pressure
-(void)didReceiveMemoryWarning {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [AppDelegate.window makeToast:@"内存不足，退出图片管理器以避免崩溃"];
}

@end
