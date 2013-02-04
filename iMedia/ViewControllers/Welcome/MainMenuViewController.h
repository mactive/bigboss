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
#import "ShakeDashboardViewController.h"

@interface MainMenuViewController : UIViewController

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)conversationAction;
- (void)updateLastMessageWithCount:(NSUInteger)lastMessageCount;

@end
