//
//  ShakeViewController.h
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ShakeViewController : UIViewController
{
    SystemSoundID completeSound;
}

@property(nonatomic, strong) UIImageView *shakeImageView;
@property(nonatomic, strong) UIView *afterView;




@end