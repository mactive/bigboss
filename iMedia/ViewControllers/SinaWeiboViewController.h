//
//  SinaWeiboViewController.h
//  jiemo
//
//  Created by meng qian on 12-12-10.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PassValueDelegate.h"

@interface SinaWeiboViewController : UIViewController

@property(nonatomic,assign) NSObject<PassValueDelegate> *passDelegate;
@property(assign, nonatomic) NSUInteger valueIndex;

@end
