//
//  GCPagedScrollViewDemoViewController.h
//  GCPagedScrollViewDemo
//
//  Created by Guillaume Campagna on 11-04-30.
//  Copyright 2011 LittleKiwi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCPagedScrollView.h"

@interface AlbumViewController : UIViewController

@property (nonatomic, readonly) GCPagedScrollView* scrollView;
@property (nonatomic, strong) NSArray *albumArray;
@property (nonatomic, readwrite) NSUInteger albumIndex;

- (UIView*) createViewAtIndex:(NSUInteger) index;

@end
