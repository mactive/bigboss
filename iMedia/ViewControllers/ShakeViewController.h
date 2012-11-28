//
//  ShakeViewController.h
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

typedef enum _BaitType
{
    BaitTypeFree = 1,
    BaitTypeDiscount = 2,
    BaitTypeCode = 3
} BaitType;

@interface ShakeViewController : UIViewController

@property(nonatomic, strong)NSDictionary *shakeData;



@end