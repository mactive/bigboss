//
//  ImageViewController.m
//  iMedia
//
//  Created by meng qian on 13-3-6.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "ImageViewController.h"
#import "UIImageView+AFNetworking.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ConvenienceMethods.h"

@interface ImageViewController ()<UIActionSheetDelegate, UIScrollViewAccessibilityDelegate>
@property(strong, nonatomic)UIImageView *imageContainer;
@property(strong, nonatomic)UIScrollView *scrollView;
@property(strong, nonatomic)UIButton *moreButton;
@property(strong, nonatomic)UIActionSheet *moreActionSheet;
@end

@implementation ImageViewController

@synthesize urlString;
@synthesize imageContainer;
@synthesize titleString;
@synthesize scrollView;
@synthesize moreButton;
@synthesize moreActionSheet;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = StringHasValue(self.titleString) ? self.titleString:T(@"查看图片") ;
    self.view.backgroundColor = [UIColor blackColor];
    
    
    self.moreButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 29)];
    [self.moreButton setBackgroundImage:[UIImage imageNamed: @"barbutton_more.png"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.moreButton];
    
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    self.scrollView.minimumZoomScale = 1; //最小到0.3倍
    self.scrollView.maximumZoomScale = 3.0; //最大到3倍
    self.scrollView.delegate = self;


    self.imageContainer = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 320, 442)];
    self.imageContainer.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.scrollView addSubview:self.imageContainer];
    [self.view addSubview:self.scrollView];
	// Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.imageContainer setImageWithURL:[NSURL URLWithString:self.urlString] placeholderImage:[UIImage imageNamed:@"template_placeholder.png"]];

}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageContainer;
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
    [library writeImageToSavedPhotosAlbum:self.imageContainer.image.CGImage
                                 metadata:nil
                          completionBlock:^(NSURL *assetURL, NSError *error) {}];
    [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"保存成功") andHideAfterDelay:2];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
