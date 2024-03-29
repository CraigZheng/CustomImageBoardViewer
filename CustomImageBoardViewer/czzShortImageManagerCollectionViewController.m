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
#import "czzImageCacheManager.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzImageViewerUtil.h"
#import "czzSettingsCentre.h"

@interface czzShortImageManagerCollectionViewController ()<czzImageDownloaderManagerDelegate>
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) NSArray *downloadedImages;
@property (readonly, nonatomic) NSArray *downloaders;
@end

@implementation czzShortImageManagerCollectionViewController
@synthesize delegate;
@synthesize managerCollectionView;
@synthesize placeholderView;
@synthesize imageViewerUtil;

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";
static NSString *downloadedImageCellIdentifier = @"downloaded_image_view_cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = settingCentre.transparentBackgroundColour;
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [managerCollectionView reloadData];
    if (self.downloadedImages.count == 0 && self.downloaders.count == 0)
    {
        placeholderView.hidden = NO;
    } else {
        placeholderView.hidden = YES;
    }
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (IBAction)tapOnBackgroundViewAction:(id)sender {
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);
    UITapGestureRecognizer *tapSender = sender;
    // If the tap gesture is located outside of the collection view.
    DDLogDebug(@"");
    if (!CGRectContainsPoint(self.managerCollectionView.frame, [tapSender locationInView:self.view])) {
        [self dismissWithCompletionHandler:nil];
    }
}

- (void)dismissWithCompletionHandler:(void(^)(void))completionHandler {
    BOOL isModalView = [self isModal];
    if (self.navigationController.viewControllers.count > 1) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
        
        [self.navigationController popViewControllerAnimated:YES];
        [CATransaction commit];
        
    } else if (isModalView) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
    } else {
        DDLogDebug(@"%s: cannot dismiss.", __PRETTY_FUNCTION__);
    }
}

#pragma mark - Getter
-(NSArray *)downloaders {
    return [[[czzImageDownloaderManager sharedManager] imageDownloaders] allObjects];
}

-(NSArray *)downloadedImages {
    // Reverse the downloaded images.
    return [[[[czzImageDownloaderManager sharedManager] downloadedImages] reverseObjectEnumerator] allObjects];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0)
        return self.downloaders.count;
    return self.downloadedImages.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];
        
        UIImageView *downloaderThumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        UILabel *downloaderLabel = (UILabel*) [cell viewWithTag:2];
        czzImageDownloader *currentDownloader = [self.downloaders objectAtIndex:indexPath.row];
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
        NSString *imgPath = [self.downloadedImages objectAtIndex:indexPath.row];
        UIImage *fullImg = [UIImage imageWithContentsOfFile:imgPath];
        UIImage *thumbnailImg = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:imgPath.lastPathComponent]];
        
        thumbnailImageView.image = thumbnailImg ? thumbnailImg : fullImg;
        
        return cell;
    }
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        czzImageDownloader *imageDownloader = [self.downloaders objectAtIndex:indexPath.row];
        [[czzImageDownloaderManager sharedManager] stopDownloadingImage:imageDownloader.imageURLString.lastPathComponent];
        [self dismissWithCompletionHandler:nil];
    }
    //downloaded image section
    else if (indexPath.section == 1) {
        // Dismiss then show the image.
        [self dismissWithCompletionHandler:^{
            if ([delegate respondsToSelector:@selector(shortImageManager:selectedImageWithIndex:inImages:)]) {
                [delegate shortImageManager:self selectedImageWithIndex:indexPath.row inImages:[self.downloadedImages copy]];
            } else {
                imageViewerUtil = [czzImageViewerUtil new];
                [imageViewerUtil showPhotos:self.downloadedImages withIndex:indexPath.row];
            }
        }];
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedUpdated:(czzImageDownloader *)downloader imageName:(NSString *)imageName progress:(CGFloat)progress {
    [self.managerCollectionView reloadData];
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    // This view controller cares only for the full size images.
    if (!downloader.isThumbnail) {
        [self.managerCollectionView reloadData];
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:SHORT_IMAGE_MANAGER_VIEW_CONTROLLER];
}
@end
