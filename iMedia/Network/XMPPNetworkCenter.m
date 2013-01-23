//
//  XMPPNetworkCenter.m
//  iMedia
//
//  Created by Xiaosi Li on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "XMPPNetworkCenter.h"
#import "XMPPFramework.h"
#import "DDLog.h"

#import "User.h"
#import "Me.h"
#import "Message.h"
#import "Channel.h"
#import "Conversation.h"
#import "ModelHelper.h"
#import "NetMessageConverter.h"
#import "ModelHelper.h"

#import "AppNetworkAPIClient.h"
#import "ContactListViewController.h"
#import "AppDelegate.h"
#import "ConvenienceMethods.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
//#define BANDWIDTH_MONITOR


static NSString * const pubsubhost = @"pubsub.192.168.1.104";
//static NSString * const pubsubhost = @"pubsub.p.wingedstone.com";

@interface XMPPNetworkCenter () <XMPPRosterDelegate, XMPPPubSubDelegate, XMPPRosterMemoryStorageDelegate, XMPPPrivacyDelegate>
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
@property (nonatomic, strong) XMPPBandwidthMonitor *xmppBandwidthMonitor;
/*@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
 @property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;
 @property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
 @property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
 @property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
 */
@property (nonatomic, strong, readonly) XMPPPubSub *xmppPubsub;
//@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage;
//@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;
@property (nonatomic, strong, readonly) XMPPPrivacy *xmppPrivacy;
@property (nonatomic) BOOL isXMPPConnected;


@end

@implementation XMPPNetworkCenter

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppPubsub;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize xmppBandwidthMonitor;
@synthesize useSSL;
@synthesize xmppPrivacy;
@synthesize isXMPPConnected;

+ (XMPPNetworkCenter *)sharedClient {
    static XMPPNetworkCenter *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[XMPPNetworkCenter alloc] init];
    });
    
    return _sharedClient;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)setupWithHostname:(NSString *)hostname andPort:(int)port
{
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
    
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
        
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
    
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
    
	xmppReconnect = [[XMPPReconnect alloc] init];

    
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
    
	//xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:@"iMediaTest.sqlite"];
    xmppRosterStorage = [[XMPPRosterMemoryStorage alloc] init];
    
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    
	xmppRoster.autoFetchRoster = NO;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = NO;
    xmppRoster.allowRosterlessOperation = NO;
    
/*    // Setup XMPP PubSub
#warning Pubsub needs to be moved to later stage where serviceJiD is available
    xmppPubsub = [[XMPPPubSub alloc] initWithServiceJID:[XMPPJID jidWithString:pubsubhost] dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
#ifdef BANDWIDTH_MONITOR
    // bandwidth monitor
    self.xmppBandwidthMonitor = [[XMPPBandwidthMonitor alloc] init];
    [xmppBandwidthMonitor  activate:xmppStream];
    [xmppBandwidthMonitor addDelegate:self delegateQueue:dispatch_get_current_queue()];
#endif
    
    //XMPP privacy
    xmppPrivacy = [[XMPPPrivacy alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    xmppPrivacy.autoClearPrivacyListInfo = NO;
    xmppPrivacy.autoRetrievePrivacyListItems = NO;
    
	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
	[xmppRoster            activate:xmppStream];
    [xmppPubsub            activate:xmppStream];
    [xmppPrivacy           activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [xmppPubsub addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [xmppPrivacy addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
*/
#warning Pubsub needs to be moved to later stage where serviceJiD is available
    xmppPubsub = [[XMPPPubSub alloc] initWithServiceJID:[XMPPJID jidWithString:pubsubhost] dispatchQueue:dispatch_get_main_queue()];
    
#ifdef BANDWIDTH_MONITOR
    // bandwidth monitor
    self.xmppBandwidthMonitor = [[XMPPBandwidthMonitor alloc] init];
    [xmppBandwidthMonitor  activate:xmppStream];
    [xmppBandwidthMonitor addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
#endif
    
    //XMPP privacy
    xmppPrivacy = [[XMPPPrivacy alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    xmppPrivacy.autoClearPrivacyListInfo = NO;
    xmppPrivacy.autoRetrievePrivacyListItems = NO;
    
	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
	[xmppRoster            activate:xmppStream];
    [xmppPubsub            activate:xmppStream];
    [xmppPrivacy           activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppPubsub addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppPrivacy addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
    
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
    
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = YES;
	allowSSLHostNameMismatch = YES;
    
    self.useSSL = YES;
    self.isXMPPConnected = NO;
    
    return YES;
}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
    [xmppPubsub removeDelegate:self];
    [xmppPrivacy removeDelegate:self];
    
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
    [xmppPubsub            deactivate];
    [xmppPrivacy           deactivate];
    
	[xmppStream disconnect];
    
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
    xmppPubsub = nil;
    xmppPrivacy = nil;
}

-(BOOL)isConnected
{
    return (![xmppStream isDisconnected]) && self.isXMPPConnected ;
}

- (BOOL)connectWithUsername:(NSString *)username andPassword:(NSString *)passwd
{
	if (![xmppStream isDisconnected]) {
		return YES;
	}
    
    //  myJID = @"customer2@192.168.1.104";
    //	myPassword = @"111";
    //   myJID = @"lix@jabber.at";
    //	myPassword = @"1234Abcd";
    
	if (username == nil || passwd == nil) {
		return NO;
	}
    
	[xmppStream setMyJID:[XMPPJID jidWithString:username]];
	password = passwd;
    
	NSError *error = nil;
	if (![xmppStream connect:&error])
	{
        DDLogError(@"Error connecting: %@", error);
		return NO;
	}
    
	return YES;
}

- (BOOL)disconnect
{
	[self goOffline];
	[xmppStream disconnect];
    
    return YES;
}


-(BOOL)sendMessage:(Message *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    
    
    XMPPMessage* msg = [NetMessageConverter newXMPPMessageFromMessage:message];
    [self.xmppStream sendElement:msg];
    
  //  NSNumber *messageSendingIndex = @([_messagesSending count]);
    //[_messagesSending setObject:message forKey:messageSendingIndex];
    return YES;
}

-(NSString *)subscribeToChannel:(NSString *)nodeName withCallbackBlock:(void (^)(NSError *))block
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSString *subID = [xmppPubsub subscribeToNode:nodeName withOptions:nil];
    if (subID && block) {
        block(nil);
    } else {
        NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
        if (block) {
            block(error);
        }
    }
    return subID;
}

- (NSString *)unsubscribeToChannel:(NSString *)nodeName withCallbackBlock:(void (^)(NSError *))block
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSString *subID = [xmppPubsub unsubscribeFromNode:nodeName];
    if (subID && block) {
        block(nil);
    } else {
        NSError *error = [[NSError alloc] initWithDomain:@"wingedstone.com" code:403 userInfo:nil];
        if (block) {
            block(error);
        }
    }
    return subID;
}

-(void)addBuddy:(NSString *)jidStr withCallbackBlock:(void (^)(NSError *))block
{/*
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    XMPPUserMemoryStorageObject* user = [self.xmppRosterStorage userForJID:[XMPPJID jidWithString:jidStr]];
    if (user != nil && [user isPendingApproval]) {
        [self acceptPresenceSubscriptionRequestFrom:jidStr andAddToRoster:YES];
    } else {
        [xmppRoster addUser:[XMPPJID jidWithString:jidStr] withNickname:nil];
    }*/
    
    [self acceptPresenceSubscriptionRequestFrom:jidStr andAddToRoster:YES];
}

-(void)removeBuddy:(NSString *)jidStr withCallbackBlock:(void (^)(NSError *))block
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppRoster removeUser:[XMPPJID jidWithString:jidStr]];
    
    if (block) {
        block(nil);
    }
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
    
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
        
		NSString *expectedCertName = nil;
        
		NSString *serverDomain = xmppStream.hostName;
		NSString *virtualDomain = [xmppStream.myJID domain];
        
		if ([serverDomain isEqualToString:@"talk.google.com"])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
        
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	isXmppConnected = YES;
    
	NSError *error = nil;
    
	if (![[self xmppStream] authenticateWithPassword:password error:&error])
	{
		DDLogError(@"Error authenticating: %@", error);
	}
    

}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    /* secureConnection doesn't work due to server send 2nd feature list which doesn't include starttls
    if (self.useSSL) {
        [[self xmppStream] secureConnection:nil];
    }*/
    
	[self goOnline];
    
    //fetch roster
    [xmppRoster fetchRoster];
    
    self.isXMPPConnected = YES;
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    if ([message isChatMessage])
	{
        Message *msg = [NetMessageConverter newMessageFromXMPPMessage:message inContext:_managedObjectContext];
        
        if (msg == nil) {
            return;
        }
        
        // MyNotificationName defined globally
        NSNotification *myNotification =
        [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:msg.conversation];
        [[NSNotificationQueue defaultQueue]
         enqueueNotification:myNotification
         postingStyle:NSPostWhenIdle
         coalesceMask:NSNotificationNoCoalescing
         forModes:nil];
	}
    
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    
    // where received subscribe success, add user to roster
    NSString* ePostalID = [[presence from] bare];
    NSString* subscriptionResult = [presence attributeStringValueForName:@"type"];
    if (subscriptionResult != nil && [subscriptionResult isEqualToString:@"subscribe"]) {
        XMPPUserMemoryStorageObject* user = [self.xmppRosterStorage userForJID:[presence from]];
        User* thisUser = [[ModelHelper sharedInstance] findUserWithEPostalID:ePostalID];
        if (user != nil && [user isBuddy]) {
            if (thisUser != nil && thisUser.state == IdentityStateActive) {
                [self acceptPresenceSubscriptionRequestFrom:ePostalID andAddToRoster:YES];
            } else {
                [self acceptPresenceSubscriptionRequestFrom:ePostalID andAddToRoster:YES];
            }
        } else if ((thisUser == nil ) || thisUser.state != IdentityStateActive) {
            NSNotification *myNotification =
            [NSNotification notificationWithName:NEW_FRIEND_NOTIFICATION object:[[presence from] bare]];
            [[NSNotificationQueue defaultQueue]
             enqueueNotification:myNotification
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationNoCoalescing
             forModes:nil];
        } else if (thisUser.state == IdentityStateActive) {
            // this is the case that the contact have removed user, and subscriptions are revoked both ways
            thisUser.state = IdentityStatePendingServerDataUpdate;
            [self acceptPresenceSubscriptionRequestFrom:ePostalID andAddToRoster:YES];
        }
        
    } else if (subscriptionResult != nil && [subscriptionResult isEqualToString:@"unsubscribe"]) {
        User* thisUser = [[ModelHelper sharedInstance] findUserWithEPostalID:ePostalID];
        if (thisUser != nil &&  thisUser.state == IdentityStatePendingAddFriend)
        {
            thisUser.state = IdentityStateInactive;
            [self removeBuddy:ePostalID withCallbackBlock:nil];
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	if (!isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
    
    self.isXMPPConnected = NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPPrivacyDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppPrivacy:(XMPPPrivacy *)sender didReceiveListNames:(NSArray *)listNames
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if ([xmppPrivacy defaultListName] == nil) {
        
        NSXMLElement *deny1 = [XMPPPrivacy privacyItemWithAction:@"deny" order:1];
        [XMPPPrivacy blockPresenceIn:deny1];
        [XMPPPrivacy blockPresenceOut:deny1];
    
        NSXMLElement *allow1 = [XMPPPrivacy privacyItemWithType:@"subscription" value:@"both" action:@"allow" order:5];
    
        NSXMLElement *deny2 = [XMPPPrivacy privacyItemWithType:@"jid" value:[xmppStream.myJID domain] action:@"deny" order:11];
        [XMPPPrivacy blockMessages:deny2];
        
        NSXMLElement *global = [XMPPPrivacy privacyItemWithAction:@"allow" order:100];
        
        NSArray *defaultList = [NSArray arrayWithObjects:deny1, allow1, deny2, global, nil];
    
        // disable localnetwork verification
        if ([pubsubhost isEqualToString:@"pubsub.192.168.1.104"]) {
            [xmppPrivacy setListWithName:@"default" items:[NSArray arrayWithObjects:global, nil]];
        } else {
            [xmppPrivacy setListWithName:@"default" items:defaultList];
        }
    
        [xmppPrivacy setDefaultListName:@"default"];
   }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterMemoryStoargeDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isBuddyWithJIDString:(NSString *)jid
{
    XMPPUserMemoryStorageObject *user = [xmppRosterStorage userForJID:[XMPPJID jidWithString:jid]];
    return [self isBuddy:user];
}

//helper function to determine roster user status:
- (BOOL)isBuddy:(XMPPUserMemoryStorageObject *)user
{
    return [user isBuddy];
}
//
// everytime some poster change happened, local user db should be updated
//
- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender didAddUser:(XMPPUserMemoryStorageObject *)user
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"add user: %@", user);
    
    NSString* ePostalID = [user.jid bare];
    NSString *meID ;
    
    XMPPUserMemoryStorageObject *me = [sender myUser];
    if (me == nil) {
        meID = [self appDelegate].me.ePostalID;
    } else {
        meID = [me.jid bare];
    }
    if ([ePostalID isEqualToString:meID]) {
        return;
    }
    
    if (![self isBuddy:user]) {
        return;
    }
    
    User* thisUser = [[ModelHelper sharedInstance] findUserWithEPostalID:ePostalID];
    
    // insert user if it doesn't exist
    if (thisUser == nil) {
        thisUser = [[ModelHelper sharedInstance] createNewUser];
    }
    
    
    if (thisUser.state != IdentityStateActive)
    {
        thisUser.ePostalID = [user.jid bare];
        thisUser.displayName = [thisUser.ePostalID substringToIndex:[thisUser.ePostalID rangeOfString: @"@"].location];
        thisUser.state = IdentityStatePendingServerDataUpdate;
        
        [[AppNetworkAPIClient sharedClient] updateIdentity:thisUser withBlock:nil];
    }
}

-(void)xmppRoster:(XMPPRosterMemoryStorage *)sender didRemoveUser:(XMPPUserMemoryStorageObject *)user
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSString* ePostalID = [user.jid bare];
    
    XMPPUserMemoryStorageObject *me = [sender myUser];
    if ([ePostalID isEqualToString:[me.jid bare]]) {
        return;
    }
    
    User* thisUser = [[ModelHelper sharedInstance] findUserWithEPostalID:ePostalID];
    
    // insert user if it doesn't exist
    if (thisUser == nil) {
        // weird - log an error
        DDLogError(@"user have to exist! ERROR NEED CHECK: %@", user);
    } else if (thisUser.state == IdentityStateActive || thisUser.state == IdentityStatePendingRemoveFriend) {
        thisUser.state = IdentityStateInactive;
//        MOCSave(_managedObjectContext);
        [[self appDelegate].contactListController contentChanged];
    } else if (thisUser.state == IdentityStatePendingAddFriend) {
        thisUser.state = IdentityStateInactive;
        //        MOCSave(_managedObjectContext);
        [[self appDelegate].contactListController contentChanged];
    }
}

//
// Implement this delegate so to create local users from the poster
// this function should only be used once
//
- (void)xmppRosterDidPopulate:(XMPPRosterMemoryStorage *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSString *meID ;
    XMPPUserMemoryStorageObject *me = [sender myUser];
    if (me == nil) {
        meID = [self appDelegate].me.ePostalID;
    } else {
        meID = [me.jid bare];
    }

    NSArray* roster = [sender unsortedUsers];
    NSInteger count = [roster count];
    for (int i = 0 ; i < count ; i++) {
        XMPPUserMemoryStorageObject *obj = [roster objectAtIndex:i];
        if ([[obj.jid bare] isEqualToString:meID]) {
            continue;
        }
        
        NSString* ePostalID = [obj.jid bare];
        User* thisUser = [[ModelHelper sharedInstance] findUserWithEPostalID:ePostalID];
        if ([obj isPendingApproval]) {
            // from roster - a pending approval friend request
            // from roster - pendign other's approval - send again
            if (thisUser == nil) {
                thisUser = [[ModelHelper sharedInstance] createNewUser];
            }
            
            thisUser.state = IdentityStatePendingAddFriend;
            
            // send sub request anyway - idempotent requests all the way
            [[XMPPNetworkCenter sharedClient] addBuddy:ePostalID withCallbackBlock:nil];
        }

        if (![self isBuddy:obj]) {
            continue;
        }
        
        // insert user if it doesn't exist
        if (thisUser == nil) {
            thisUser = [[ModelHelper sharedInstance] createNewUser];
            thisUser.name = obj.nickname;
            thisUser.ePostalID = [obj.jid bare];
            thisUser.displayName = [thisUser.ePostalID substringToIndex:[thisUser.ePostalID rangeOfString: @"@"].location];
            thisUser.type = IdentityTypeUser;
            thisUser.state = IdentityStatePendingServerDataUpdate;
            
            [[AppNetworkAPIClient sharedClient] updateIdentity:thisUser withBlock:nil];
        } else {
            if (thisUser.state == IdentityStatePendingServerDataUpdate) {
                [[AppNetworkAPIClient sharedClient] updateIdentity:thisUser withBlock:nil];
            }
        }
    }
    
    [[self appDelegate] saveContextInDefaultLoop];
}


//NEED TO CHECK THIS AGAIN TO SEE WHAT HAPPENS. this function should be called only when the user is already on
//our roster. But we may, or may not be on the user's roster yet. Our state should only be active when we are on
//the other's roster
//Comment this out because it let a user to add another user without consent.
- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender didUpdateUser:(XMPPUserMemoryStorageObject *)user
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    DDLogVerbose(@"update user: %@", user);
    
    NSString* ePostalID = [user.jid bare];
    NSString *meID ;
    
    XMPPUserMemoryStorageObject *me = [sender myUser];
    if (me == nil) {
        meID = [self appDelegate].me.ePostalID;
    } else {
        meID = [me.jid bare];
    }
    if ([ePostalID isEqualToString:meID]) {
        return;
    }
    
    User* thisUser = [[ModelHelper sharedInstance] findUserWithEPostalID:ePostalID];
    
    if ([user isPendingApproval]) {
        // doing nothing and wait for the approval
    } else if (![self isBuddy:user]) {
        // if the user is marked active in our contact list, we will remove it
        if (thisUser == nil) {
            // weird - log an error
            DDLogError(@"user have to exist! ERROR NEED CHECK: %@", user);
        } else if (thisUser.state == IdentityStateActive || thisUser.state == IdentityStatePendingRemoveFriend) {
            thisUser.state = IdentityStateInactive;
            [[self appDelegate].contactListController contentChanged];
        }
    } else {
        // insert user if it doesn't exist
        if (thisUser == nil) {
            thisUser = [[ModelHelper sharedInstance] createNewUser];
        }
        
        // if this user is in pending add friend state, then send a friend add message
        if (thisUser.state == IdentityStatePendingAddFriend) {
            //who approved you as a friend
            Message *msg = [NetMessageConverter createFriendRequestApprovedMessageFromUser:thisUser inContext:_managedObjectContext];
            
            if (msg == nil) {
                return;
            }
            
            // MyNotificationName defined globally
            NSNotification *myNotification =
            [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:msg.conversation];
            [[NSNotificationQueue defaultQueue]
             enqueueNotification:myNotification
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationNoCoalescing
             forModes:nil];
        }
        
        if ( thisUser.state != IdentityStateActive)
        {
            thisUser.ePostalID = [user.jid bare];
            thisUser.state = IdentityStatePendingServerDataUpdate;
            
            [[AppNetworkAPIClient sharedClient] updateIdentity:thisUser withBlock:nil];
        }
    }

    [[self appDelegate] saveContextInDefaultLoop];
}

/*
- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}
 */


- (void)acceptPresenceSubscriptionRequestFrom:(NSString *)jidStr andAddToRoster:(BOOL)flag
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    [xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:flag];
}

- (void)rejectPresenceSubscriptionRequestFrom:(NSString *)jidStr
{
    [xmppRoster rejectPresenceSubscriptionRequestFrom:[XMPPJID jidWithString:jidStr]];
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPPubsubDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveMessage:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    // if haven't setup users, discard message
    if ([self appDelegate].me == nil) {
        return;
    }
    
        
    Message *msg = [NetMessageConverter newMessageFromXMPPPubsubMessage:message inContext:_managedObjectContext];
    
    if (msg == nil) {
        return;
    }
    
    // MyNotificationName defined globally
    NSNotification *myNotification =
    [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:msg.conversation];
    [[NSNotificationQueue defaultQueue]
     enqueueNotification:myNotification
     postingStyle:NSPostWhenIdle
     coalesceMask:NSNotificationNoCoalescing
     forModes:nil];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didSubscribe:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // <iq from="pubsub.host.com" to="user@host.com/rsrc" id="ABC123:subscribenode" type="result">
    //   <pubsub xmlns="http://jabber.org/protocol/pubsub">
    //     <subscription jid="tv@xmpp.local" subscription="subscribed" subid="DEF456"/>
    //   </pubsub>
    // </iq>
    

    NSXMLElement *pubsub = [iq elementForName:@"pubsub"];
    NSString *subrequestID = [iq attributeStringValueForName:@"id"];
    NSXMLElement *subscription = [pubsub elementForName:@"subscription"];
    NSString* subID = [subscription attributeStringValueForName:@"subid"];
    NSString *nodeStr = [subscription attributeStringValueForName:@"node"];
    
    //add the Channel to the addressbook
    Channel *channel;
    if (nodeStr == nil)
        channel = [[ModelHelper sharedInstance] findChannelWithSubrequestID:subrequestID];
    else
        channel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
    
    if (!channel || channel.state == IdentityStateActive) {
        return;
    }
    
    
    NSString* csrftoken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    // notify server about the subscription 
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys: channel.guid, @"guid", @"4", @"op", csrftoken, @"csrfmiddlewaretoken", nil];
        
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"set subscription succeeded: %@", responseObject);
        
        if (channel && channel.state != IdentityStateActive) {
            channel.state = IdentityStateActive;
            channel.subID = subID;
            [[self appDelegate].contactListController contentChanged];
            [[self appDelegate] saveContextInDefaultLoop];
        }
            
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"login failed: %@", error);
        if (channel != nil) {
            channel.subrequestID = [self subscribeToChannel:channel.node withCallbackBlock:nil];
        } else if (StringHasValue(nodeStr)) {
            channel.subrequestID = [self subscribeToChannel:nodeStr withCallbackBlock:nil];
        }

    }];

}
- (void)xmppPubSub:(XMPPPubSub *)sender didUnsubscribe:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // <iq from="pubsub.host.com" to="user@host.com/rsrc" id="ABC123:subscribenode" type="result">
    //   <pubsub xmlns="http://jabber.org/protocol/pubsub">
    //     <subscription jid="tv@xmpp.local" subscription="unsubscribed" subid="DEF456"/>
    //   </pubsub>
    // </iq>
    
    
    NSXMLElement *pubsub = [iq elementForName:@"pubsub"];
    NSString *subrequestID = [iq attributeStringValueForName:@"id"];
    NSXMLElement *subscription = [pubsub elementForName:@"subscription"];
    NSString* subID = [subscription attributeStringValueForName:@"subid"];
    NSString *nodeStr = [subscription attributeStringValueForName:@"node"];
    
    //unsubscribe this channel
    Channel *channel;
    if (nodeStr == nil)
        channel = [[ModelHelper sharedInstance] findChannelWithSubrequestID:subrequestID];
    else
        channel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
    
    if (!channel || channel.state == IdentityStateInactive) {
        return;
    }

    NSString* csrftoken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    // notify server about the subscription
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys: channel.guid, @"guid", @"5", @"op", csrftoken, @"csrfmiddlewaretoken", nil];
    
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"remove subscription succeeded: %@", responseObject);
        
        //unsubscribe this channel
        if (channel && channel.state != IdentityStateInactive) {
            channel.state = IdentityStateInactive;
            channel.subID = subID;
            [[self appDelegate].contactListController contentChanged];
            [[self appDelegate] saveContextInDefaultLoop];;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
#warning Need to handle grace period - don't upload all the time
        if (channel != nil) {
            channel.subrequestID = [self unsubscribeToChannel:channel.node withCallbackBlock:nil];
        } else if (StringHasValue(nodeStr)) {
            channel.subrequestID = [self unsubscribeToChannel:nodeStr withCallbackBlock:nil];
        }
    }];
}


@end
