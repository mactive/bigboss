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

@interface AlbumViewController ()
- (UIView*) createViewForObj:(id)obj;
@end

@implementation AlbumViewController
@synthesize albumArray;
@synthesize albumIndex;

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    GCPagedScrollView* scrollView = [[GCPagedScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.view = scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.backgroundColor = [UIColor blackColor];

    for (NSUInteger index = 0; index < [self.albumArray count]; index ++) {
        //You add your content views here
        id obj = [self.albumArray objectAtIndex:index];
        if ([obj isKindOfClass:[Avatar class]]) {
            Avatar * singleAvatar = obj;
            if (singleAvatar.image == nil) {
                continue;
            }
        } else if ([obj isKindOfClass:[ImageRemote class]]) {
            ImageRemote *imageRemote = obj;
            if (imageRemote.imageThumbnailURL == nil || [imageRemote.imageThumbnailURL isEqualToString:@""]) {
                continue;
            }
        } else {
            continue;
        }
        
        [self.scrollView addContentSubview:[self createViewForObj:obj]];
    }
}

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
    if ([obj isKindOfClass:[Avatar class]]) {
        Avatar * singleAvatar = obj;
        [imageView setImage:singleAvatar.image];
    } else if ([obj isKindOfClass:[ImageRemote class]]) {
        ImageRemote *imageRemote = obj;
        [imageView setImageWithURL:[NSURL URLWithString:imageRemote.imageThumbnailURL] placeholderImage:nil];
    }
    
    [imageView setContentMode:UIViewContentModeScaleAspectFit];

    [view addSubview:imageView];
    
    
    return view;
}

@end
