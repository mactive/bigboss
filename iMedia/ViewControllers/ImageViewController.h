//
//  ImageViewController.h
//  iMedia
//
//  Created by meng qian on 13-3-6.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BBCustomBackButtonViewController.h"
@interface ImageViewController : BBCustomBackButtonViewController
@property(strong, nonatomic)NSString *urlString;
@property(strong, nonatomic)NSString *titleString;
@end
