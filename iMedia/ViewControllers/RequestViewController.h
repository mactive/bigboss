//
//  RequestViewController.h
//  iMedia
//
//  Created by qian meng on 12-10-29.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RequestViewController : UIViewController

@property(nonatomic, strong) NSDictionary * requestDict;
@property(nonatomic, strong) UIView * requestView;
@property(nonatomic, strong) UILabel * titleLabel;
@property(nonatomic, strong) UILabel * timeLabel;

@property(nonatomic, strong) UIView * contentView;

@property(nonatomic, strong) UIButton * confirmButton;
@property(nonatomic, strong) UIButton * cancelButton;

@end
