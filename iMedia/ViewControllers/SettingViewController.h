//
//  SettingViewController.h
//  iMedia
//
//  Created by qian meng on 12-10-17.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ProfileMeController;

@interface SettingViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) UITableView *settingTableView;
@property(nonatomic, strong) UIButton *loginButton;

@property(nonatomic, strong) NSArray *settingTitleArray;
@property(nonatomic, strong) NSArray *settingDescArray;


@end

