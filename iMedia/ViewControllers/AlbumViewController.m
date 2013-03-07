//
//  GCPagedScrollViewDemoViewController.m
//  GCPagedScrollViewDemo
//
//  Created by Guillaume Campagna on 11-04-30.
//  Copyright 2011 LittleKiwi. All rights reserved.
//

#import "AlbumViewController.h"
#import "Avatar.h"
#import "ImageRemote.h"
#import "UIImageView+AFNetworking.h"
#import "UIImage+ProportionalFill.h"
#import "MBProgressHUD.h"
#import "DDLog.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ConvenienceMethods.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface AlbumViewController ()<UIScrollViewAccessibilityDelegate,UIActionSheetDelegate>
- (UIView*) createViewForObj:(id)obj;
@property(strong, nonatomic)UIView *targetView;
@property(strong, nonatomic)UIButton *moreButton;
@property(strong, nonatomic)NSMutableArray *targetArray;
@property(strong, nonatomic)UIActionSheet *moreActionSheet;
@end

@implementation AlbumViewController
@synthesize albumArray;
@synthesize albumIndex;
@synthesize targetView;
@synthesize targetArray;
@synthesize moreButton;
@synthesize moreActionSheet;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GCPagedScrollView* scrollView = [[GCPagedScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.view = scrollView;
    self.targetArray = [[NSMutableArray alloc]init];
    
    self.targetView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 432)];
    self.scrollView.backgroundColor = [UIColor blackColor];
    
    self.moreButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 29)];
    [self.moreButton setBackgroundImage:[UIImage imageNamed: @"barbutton_more.png"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.moreButton];
    

    self.scrollView.minimumZoomScale = 1; //最小到0.3倍
    self.scrollView.maximumZoomScale = 3.0; //最大到3倍
    self.scrollView.clipsToBounds = YES;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;

    
    for (NSUInteger index = 0; index < [self.albumArray count]; index ++) {
        //You add your content views here
        id obj = [self.albumArray objectAtIndex:index];
        if ([obj isKindOfClass:[Avatar class]]) {
            Avatar * singleAvatar = obj;
            if (singleAvatar.image == nil && (singleAvatar.imageRemoteURL == nil || [singleAvatar.imageRemoteURL isEqualToString:@""]) ) {
                continue;
            }
        } else if ([obj isKindOfClass:[ImageRemote class]]) {
            ImageRemote *imageRemote = obj;
            if (!StringHasValue(imageRemote.imageURL)) {
                continue;
            }
        } else if ([obj isKindOfClass:[NSString class]]) {
            NSString *urlPath = obj;
            if (!StringHasValue(urlPath)) {
                continue;
            }
        }else {
            continue;
        }
        
        [self.scrollView addContentSubview:[self createViewForObj:obj]];
        [self.targetArray addObject:[self createViewForObj:obj]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.scrollView setPage:self.albumIndex];
    
    self.targetView = [self.targetArray objectAtIndex:self.scrollView.page];
    DDLogVerbose(@"page %d %@",self.scrollView.page,self.targetView);
    self.title = [NSString stringWithFormat:@"%d/%d",self.scrollView.page+1,[self.albumArray count]];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.scrollView]) {
        DDLogVerbose(@"End page %d %@",self.scrollView.page,self.targetView);
        self.targetView = [self.targetArray objectAtIndex:self.scrollView.page];
        self.title = [NSString stringWithFormat:@"%d/%d",self.scrollView.page+1,[self.albumArray count]];
    }

}

//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
//{
//    DDLogVerbose(@"Zoom scroll %@",self.targetView);
//    DDLogVerbose(@"Zoom page %d %@",self.scrollView.page,self.targetView);
//    return self.targetView;
//}
//- (void)scrollViewDidZoom:(UIScrollView *)scrollView
//{
////    UIImageView *target = (UIImageView *)[self.targetView viewWithTag:1001];
//
//    DDLogVerbose(@"DID ZOOM %@ %@",self.scrollView,self.targetView);
//
//    self.targetView.frame = [self centeredFrameForScrollView:self.scrollView andUIView:self.targetView];
//
//}
//- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
//    CGSize boundsSize = scroll.bounds.size;
//    CGRect frameToCenter = rView.frame;
//    // center horizontally
//    if (frameToCenter.size.width < boundsSize.width) {
//        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
//    }
//    else {
//        frameToCenter.origin.x = 0;
//    }
//    // center vertically
//    if (frameToCenter.size.height < boundsSize.height) {
//        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
//    }
//    else {
//        frameToCenter.origin.y = 0;
//    }
//    return frameToCenter;
//}


#pragma mark -
#pragma mark Getters

- (GCPagedScrollView *)scrollView {
    return (GCPagedScrollView*) self.view;
}


#pragma mark -
#pragma mark Helper methods

- (UIView *)createViewForObj:(id)obj {
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 20,
                                                            self.view.frame.size.height - 50)];
    
    view.backgroundColor = [UIColor blackColor];
    UIImageView* imageView = [[UIImageView alloc]initWithFrame:view.bounds];
    imageView.tag = 1001;
    if ([obj isKindOfClass:[Avatar class]]) {
        Avatar * singleAvatar = obj;
        if (singleAvatar.image != nil) {
            [imageView setImage:singleAvatar.image];
        } else {
            [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:singleAvatar.imageRemoteURL]] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {

                singleAvatar.image = image;
                if (singleAvatar.thumbnail == nil) {
                    singleAvatar.thumbnail = [image imageCroppedToFitSize:CGSizeMake(75, 75)];
                }
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                
            }];
        }
    } else if ([obj isKindOfClass:[ImageRemote class]]) {
        ImageRemote *imageRemote = obj;
        [imageView setImageWithURL:[NSURL URLWithString:imageRemote.imageThumbnailURL] placeholderImage:nil];
    } else if ([obj isKindOfClass:[NSString class]]) {
#warning when is this being used? would the use of HUD causing the user stuck in there waiting for load finish?
        // HUD
        MBProgressHUD *hud2 = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud2.removeFromSuperViewOnHide = YES;
        
        [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:obj]] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            [hud2 hide:YES];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            [hud2 hide:YES];
        }];
    }
    
    [imageView setContentMode:UIViewContentModeScaleAspectFit];

    [view addSubview:imageView];
    return view;
}
/////////////////////////////////////////////////////////////////////
// moreaction
/////////////////////////////////////////////////////////////////////
- (void)moreAction
{
    self.moreActionSheet = [[UIActionSheet alloc]
                            initWithTitle:nil
                            delegate:self
                            cancelButtonTitle:T(@"取消")
                            destructiveButtonTitle:nil
                            otherButtonTitles: T(@"保存到手机"),nil];
    self.moreActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [self.moreActionSheet showFromRect:self.view.bounds inView:self.view animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.moreActionSheet) {
        if (buttonIndex == 0) {
            [self savePhotoToLibaray];
        }
    }
    
}

- (void)savePhotoToLibaray
{
    // Save Video to Photo Album
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    UIImageView *targetImageView = (UIImageView *)[self.targetView viewWithTag:1001];
    [library writeImageToSavedPhotosAlbum:targetImageView.image.CGImage
                                 metadata:nil
                          completionBlock:^(NSURL *assetURL, NSError *error) {}];
    [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"保存成功") andHideAfterDelay:2];
}

@end
