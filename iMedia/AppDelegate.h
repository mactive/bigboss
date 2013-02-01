//
//  AppDelegate.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDefs.h"
#import "MainMenuViewController.h"

@class ContactListViewController;
@class ConversationsController;
@class FunctionListViewController;
@class SettingViewController;
@class ShakeDashboardViewController;
@class CompanyCategoryViewController;
@class MyCompanyViewController;
@class MemoViewController;
@class Message;
@class Me;
@class Pluggin;
@class Information;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainMenuViewController *mainMenuViewController;
@property (strong, nonatomic) ConversationsController *conversationController;
@property (strong, nonatomic) ContactListViewController *contactListController;
@property (strong, nonatomic) ShakeDashboardViewController *shakeDash;
@property (strong, nonatomic) SettingViewController *settingViewController;
@property (strong, nonatomic) CompanyCategoryViewController *companyCategoryViewController;
@property (strong, nonatomic) MyCompanyViewController *myCompanyController;
@property (strong, nonatomic) MemoViewController *memoViewController;
@property (strong, nonatomic) ShakeDashboardViewController *shakeDashboardViewController;


// Here comes one of the bigges assumptions. This me is the only instance in the Me entity. If me exists, it means
// this is not a first run, all data initializations will be done already. We will not pull the full poster again
// and update our addressbook
//
// if me is nil, it is the first run. a full poster fetch will be performed, welcome section will be displayed, and
// initial data population will be done.
@property (strong, nonatomic) Me *me;
@property (nonatomic) int unreadMessageCount;

// Here is a list of all available pluggins;
@property (strong, nonatomic) Pluggin *friendRequestPluggin;

- (void)transformPrivacyLogin;
- (void)startMainSession;
- (void)startIntroSession;
- (void)createMeAndOtherOneTimeObjectsWithUsername:(NSString *)username password:(NSString *)passwd jid:(NSString *)jidStr jidPasswd:(NSString *)jidPass andGUID:(NSString *)guid withBlock:(void (^)(id responseObject, NSError *error))block;
- (NSManagedObjectContext *)context;
- (void) disableLeftBarButtonItemOnNavbar:(BOOL)disable;
- (void)clearSession;
- (void)updateMyCompanyInformation:(NSNotification *)notification;

- (void)saveContextInDefaultLoop;
@end


