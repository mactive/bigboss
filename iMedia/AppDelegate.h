//
//  AppDelegate.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMPPNetworkCenter.h"

@class ContactListViewController;
@class ConversationsController;
@class Message;
@class Me;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabController;
@property (strong, nonatomic) ConversationsController *conversationController;
@property (strong, nonatomic) ContactListViewController *contactListController;

@property (strong, nonatomic) Me *me;

- (void)startMainSession;
- (void)createMeWithUsername:(NSString *)username password:(NSString *)passwd jid:(NSString *)jidStr andJidPasswd:(NSString *)jidPass;

@end


