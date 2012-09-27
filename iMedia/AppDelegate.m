//
//  AppDelegate.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "Message.h"
#import "User.h"
#import "Me.h"
#import "Conversation.h"
#import "AppDefs.h"
#import <CocoaPlant/NSManagedObject+CocoaPlant.h>

#import "ConversationsController.h"
#import "ContactListViewController.h"
#import "FirstLoginController.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define NAVIGATION_CONTROLLER() ((UINavigationController *)_window.rootViewController)



@interface AppDelegate()
{
    NSManagedObjectContext *_managedObjectContext;
    Conversation  *_conversation; // this is a mock
    NSMutableDictionary     *_messagesSending;
    SystemSoundID           _messageReceivedSystemSoundID;
    SystemSoundID           _messageSentSystemSoundID;
}
- (void)setupStream;
- (void)teardownStream;
- (void)setupRoster;
-(void)startIntroSession;

- (void)goOnline;
- (void)goOffline;

@end


@implementation AppDelegate

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppPubsub;
/*
@synthesize xmppvCardStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize xmppMessageArchiving;
@synthesize xmppMessageArchivingStorage;
*/

@synthesize window = _window;
@synthesize tabController = _tabController;
@synthesize conversationController;
@synthesize contactListController;

@synthesize me = _me;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    // Setup the XMPP stream
	[self setupStream];

    
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"iMedia" withExtension:@"momd"]]];
    NSError *error;
    NSAssert([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"iMedia.sqlite"] options:nil error:&error], @"Add-Persistent-Store Error: %@", error);
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    
    // check whether first user
    NSArray *fetchedUsers = MOCFetchAll(_managedObjectContext, @"Me");
    if ([fetchedUsers count] == 0) {
        [self startIntroSession];
    } else if ([fetchedUsers count] == 1) {
        self.me = [fetchedUsers objectAtIndex:0];
        [self startMainSession];
    } else {
        DDLogVerbose(@"%@: %@ multiple ME instance", THIS_FILE, THIS_METHOD);
    }

    return YES;
}

- (void)startIntroSession
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewUserWelcome" bundle:nil];
    FirstLoginController *loginViewController = [storyboard instantiateInitialViewController];
    
    [self.window addSubview:loginViewController.view];
    [self.window setRootViewController:loginViewController];
    [self.window makeKeyAndVisible];
}

- (void)startMainSession
{
    if (![self connect])
	{
        DDLogVerbose(@"%@: %@ cannot connect to server", THIS_FILE, THIS_METHOD);
	}
    //
    // Creating all the initial controllers
    //
    self.tabController = [[UITabBarController alloc] init];
    self.contactListController = [[ContactListViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.contactListController];
    self.contactListController.managedObjectContext = _managedObjectContext;
    self.conversationController.title = NSLocalizedString(@"Contacts", nil);
    
    self.conversationController = [[ConversationsController alloc] init];
    UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:self.conversationController];
    self.conversationController.managedObjectContext = _managedObjectContext;
    self.conversationController.title = NSLocalizedString(@"Messages", nil);
    
    NSArray* controllers = [NSArray arrayWithObjects:navController2, navController, nil];
    self.tabController.viewControllers = controllers;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window addSubview:self.tabController.view];
    [self.window setRootViewController:self.tabController];
    [self.window makeKeyAndVisible];

    if(self.me == nil) {
        [self setupRoster];
    }
}

- (void)dealloc
{
	[self teardownStream];
}

- (void)setupStream
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
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        
    // Setup XMPP PubSub
    xmppPubsub = [[XMPPPubSub alloc] initWithServiceJID:[XMPPJID jidWithString:@"pubsub.192.168.1.104"]];
    [xmppPubsub subscribeToNode:@"summer" withOptions:nil];
    
    
	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
	[xmppRoster            activate:xmppStream];
    [xmppPubsub            activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppPubsub addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
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
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;
}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
    [xmppPubsub removeDelegate:self];
    
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
    [xmppPubsub            deactivate];
    
	[xmppStream disconnect];
    
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
    xmppPubsub = nil;
}

// Only for first use to initialize User db with full poster. All future add/remove user will be handled via
// individual request
- (void)setupRoster
{

    XMPPUserMemoryStorageObject* meXMPP = [xmppRosterStorage myUser];
    NSArray* roster = [xmppRosterStorage unsortedUsers];

    self.me = [NSEntityDescription insertNewObjectForEntityForName:@"Me" inManagedObjectContext:_managedObjectContext];
    self.me.ePostalID = [meXMPP.jid bare];
    self.me.name = meXMPP.nickname;
    self.me.username = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
	self.me.password = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];

    
    NSInteger count = [roster count];
    for (int i = 0; i < count; i++) {
        XMPPUserMemoryStorageObject* obj = [roster objectAtIndex:i];
        User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
        user.name = obj.nickname;
        user.ePostalID = [obj.jid bare];
    }
    
    MOCSave(_managedObjectContext);
    
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
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
	if (![xmppStream isDisconnected]) {
		return YES;
	}
    
	NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	if (self.me != nil) {
        myJID = self.me.username;
        myPassword = self.me.password;
    }
    
  //  myJID = @"customer2@192.168.1.104";
//	myPassword = @"111";
 //   myJID = @"lix@jabber.at";
//	myPassword = @"1234Abcd";
    
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    
	[xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
	password = myPassword;
    
	NSError *error = nil;
	if (![xmppStream connect:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
	return YES;
}

- (void)disconnect
{
	[self goOffline];
	[xmppStream disconnect];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self disconnect];
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    _messagesSending = [NSMutableDictionary dictionary];
    [self connect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    if (_managedObjectContext != nil) {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Work between Message & XMPPMessage
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (User *)findUserWithEPostalID:(NSString *)ePostalID
{
    NSManagedObjectContext *moc = _managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"User" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(ePostalID = %@)", ePostalID];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];

    if ([array count] == 0)
    {
        DDLogError(@"User doesn't exist: %@", error);
        return nil;
    } else {
        if ([array count] > 1) {
            DDLogError(@"More than one user object with same postal id: %@", ePostalID);
        }
        return [array objectAtIndex:0];
    }
}
- (void)addMessageWithXMPPMessage:(XMPPMessage *)msg {
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:_managedObjectContext];

    User *from = [self findUserWithEPostalID:[[msg from] bare]];
    if (from == nil)
    {
        DDLogError(@"User doesn't exist");
        return;
    }
    
    message.from = from;
    message.sentDate = [NSDate date];
    message.text = [[msg elementForName:@"body"] stringValue];
    message.type = [NSNumber numberWithInt:MessageTypeChat];
    
    // Find a conversation that this message belongs. That is judged by the conversation's user list.
    NSSet *results = [from.conversations objectsPassingTest:^(id obj, BOOL *stop){
        Conversation *conv = (Conversation *)obj;
        if ([conv.users count] == 1) {
            return YES;
        }
        return NO;
    }];
    
    
    Conversation *conv;
    if ([results count] == 0)
    {
        conv = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_managedObjectContext];
        [conv addUsersObject:from];
    } else {
        conv = [results anyObject];
    }
    conv.lastMessageSentDate = message.sentDate;
    conv.lastMessageText = message.text;
    [conv addMessagesObject:message];

    
    // MyNotificationName defined globally
    NSNotification *myNotification =
    [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:conv];
    [[NSNotificationQueue defaultQueue]
     enqueueNotification:myNotification
     postingStyle:NSPostWhenIdle
     coalesceMask:NSNotificationNoCoalescing
     forModes:nil];
    
}

- (void)sendChatMessage:(Message *)message {
    // Send message.
    // TODO: Prevent this message from getting saved to Core Data if I hit back.
    User *to = [message.conversation.users anyObject];
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:to.ePostalID]];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:message.text];
    [msg  addChild:body];
    [self.xmppStream sendElement:msg];
    
    NSNumber *messageSendingIndex = @([_messagesSending count]);
    [_messagesSending setObject:message forKey:messageSendingIndex];
    
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
    
	[self goOnline];
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

    if ([message isChatMessageWithBody])
	{
		XMPPUserMemoryStorageObject *user = [xmppRosterStorage userForJID:[[message from] bareJID]];
        
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];

		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		{
            [self addMessageWithXMPPMessage:message];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
 
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
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
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
/*
	XMPPUserMemoryStorageObject *user = [xmppRosterStorage userForJID:[presence from]];
    
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
    
	if (![displayName isEqualToString:jidStrBare])
	{
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
    
    
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	}
	else
	{
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
        
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
 */   
}

#define NS_PUBSUB_EVENT    @"http://jabber.org/protocol/pubsub#event"


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPPubsubDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveMessage:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSXMLElement *event = [message elementForName:@"event" xmlns:NS_PUBSUB_EVENT];
    NSString *entry = [event stringValue];

    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        Message *msg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:_managedObjectContext];
        
        User *from = [self findUserWithEPostalID:[[message from] bare]];
        if (from == nil)
        {
            DDLogError(@"User doesn't exist");
            return;
        }
        
        msg.from = from;
        msg.sentDate = [NSDate date];
        msg.text = entry;
        msg.type = [NSNumber numberWithInt:MessageTypePublish];
        
        // Find a conversation that this message belongs. That is judged by the conversation's user list.
        NSSet *results = [from.conversations objectsPassingTest:^(id obj, BOOL *stop){
            Conversation *conv = (Conversation *)obj;
            if ([conv.users count] == 1) {
                return YES;
            }
            return NO;
        }];
        
        
        Conversation *conv;
        if ([results count] == 0)
        {
            conv = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:_managedObjectContext];
            [conv addUsersObject:from];
        } else {
            conv = [results anyObject];
        }
        conv.lastMessageSentDate = msg.sentDate;
        conv.lastMessageText = [[event elementForName:@"text"] stringValue];
        [conv addMessagesObject:msg];
        
        
        // MyNotificationName defined globally
        NSNotification *myNotification =
        [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:conv];
        [[NSNotificationQueue defaultQueue]
         enqueueNotification:myNotification
         postingStyle:NSPostWhenIdle
         coalesceMask:NSNotificationNoCoalescing
         forModes:nil];
        
    }
    
    /*
    
	// A simple example of inbound message handling.
    
	if ([message isChatMessageWithBody])
	{
		XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
		                                                         xmppStream:xmppStream
		                                               managedObjectContext:[self managedObjectContext_roster]];
        
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                                message:body
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
			[alertView show];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
     */
    
}


@end
