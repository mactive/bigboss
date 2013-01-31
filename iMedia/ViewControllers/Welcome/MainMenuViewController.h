//
//  MainMenuViewController.h
//  iMedia
//
//  Created by meng qian on 13-1-24.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConversationsController.h"
#import "ContactListViewController.h"
#import "FunctionListViewController.h"
#import "SettingViewController.h"
#import "CompanyCategoryViewController.h"
#import "MyCompanyViewController.h"
#import "MemoViewController.h"

@interface MainMenuViewController : UIViewController

@property(strong, nonatomic) ConversationsController *conversationController;
@property(strong, nonatomic) ContactListViewController *contactListViewController;
@property(strong, nonatomic) FunctionListViewController *functionListViewController;
@property(strong, nonatomic) SettingViewController *settingViewController;
@property(strong, nonatomic) CompanyCategoryViewController *companyCategoryViewController;
@property(strong, nonatomic) MyCompanyViewController *myCompanyController;
@property(strong, nonatomic) MemoViewController *memoViewController;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
