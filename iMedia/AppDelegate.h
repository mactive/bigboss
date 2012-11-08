//
//  AppDelegate.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContactListViewController;
@class ConversationsController;
@class FunctionListViewController;
@class SettingViewController;
@class Message;
@class Me;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabController;
@property (strong, nonatomic) ConversationsController *conversationController;
@property (strong, nonatomic) ContactListViewController *contactListController;
@property (strong, nonatomic) FunctionListViewController *functionListController;
@property (strong, nonatomic) SettingViewController *settingController;

// Here comes one of the bigges assumptions. This me is the only instance in the Me entity. If me exists, it means
// this is not a first run, all data initializations will be done already. We will not pull the full poster again
// and update our addressbook
//
// if me is nil, it is the first run. a full poster fetch will be performed, welcome section will be displayed, and
// initial data population will be done.
@property (strong, nonatomic) Me *me;

- (void)startMainSession;
- (void)createMeWithUsername:(NSString *)username password:(NSString *)passwd jid:(NSString *)jidStr jidPasswd:(NSString *)jidPass andGUID:(NSString *)guid withBlock:(void (^)(id responseObject, NSError *error))block;
- (NSManagedObjectContext *)context;
- (void) disableLeftBarButtonItemOnNavbar:(BOOL)disable;

@end


