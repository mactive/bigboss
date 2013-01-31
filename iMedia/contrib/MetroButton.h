//
//  MetroButton.h
//  iMedia
//
//  Created by meng qian on 12-11-5.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MetroButton : UIButton

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSArray *colorArray;
@property (nonatomic, strong) UILabel *badgeLabel;

- (void)initMetroButton:(UIImage *)image andText:(NSString *)titleString andIndex:(NSUInteger)index;
- (void)setBadgeNumber:(NSUInteger )badgeNumber;

@end
