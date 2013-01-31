//
//  SettingViewController.h
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BBCustomBackButtonViewController.h"
@class ProfileMeController;

@interface SettingViewController : BBCustomBackButtonViewController<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;


@end

