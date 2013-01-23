//
//  WebViewController.h
//  iMedia
//
//  Created by meng qian on 12-11-9.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BBCustomBackButtonViewController.h"

@interface WebViewController : BBCustomBackButtonViewController

@property(strong, nonatomic)NSString *urlString;
@property(strong, nonatomic)NSString *titleString;

@end
