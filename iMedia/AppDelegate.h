//
//  AppDelegate.h
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMPPFramework.h"

@class ContactListViewController;
@class ConversationsController;
@class Message;
@class Me;

@interface AppDelegate : UIResponder <UIApplicationDelegate, XMPPRosterDelegate, XMPPPubSubDelegate>
{
    
    NSString *password;
    
	BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
    
	BOOL isXmppConnected;
}

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterMemoryStorage *xmppRosterStorage;
/*@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
 */
@property (nonatomic, strong, readonly) XMPPPubSub *xmppPubsub;
//@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage;
//@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabController;
@property (strong, nonatomic) ConversationsController *conversationController;
@property (strong, nonatomic) ContactListViewController *contactListController;

@property (strong, nonatomic) Me *me;

//- (NSManagedObjectContext *)managedObjectContext_roster;
//- (NSManagedObjectContext *)managedObjectContext_capabilities;
//- (NSManagedObjectContext *)managedObjectContext_archive;

- (BOOL)connect;
- (void)disconnect;

- (void)startMainSession;

- (void)sendChatMessage:(Message *)message;

@end


