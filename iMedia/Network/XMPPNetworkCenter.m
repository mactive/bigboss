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
#import "Message.h"
#import "Channel.h"
#import "Conversation.h"
#import "ModelHelper.h"
#import "NetMessageConverter.h"
#import "ModelHelper.h"

#import "AppNetworkAPIClient.h"

#import "AppDelegate.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

//static NSString * const pubsubhost = @"pubsub.192.168.1.104"
static NSString * const pubsubhost = @"pubsub.121.12.104.95";

@interface XMPPNetworkCenter () <XMPPRosterDelegate, XMPPPubSubDelegate, XMPPRosterMemoryStorageDelegate>
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


@end

@implementation XMPPNetworkCenter

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppPubsub;
@synthesize managedObjectContext = _managedObjectContext;

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
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    xmppRoster.allowRosterlessOperation = YES;
    
    // Setup XMPP PubSub
#warning Pubsub needs to be moved to later stage where serviceJiD is available
    xmppPubsub = [[XMPPPubSub alloc] initWithServiceJID:[XMPPJID jidWithString:pubsubhost]];
    
    
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
    
    return YES;
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

-(BOOL)isConnected
{
    return ![xmppStream isDisconnected];
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

-(void)subscribeToChannel:(NSString *)nodeName withCallbackBlock:(void (^)(NSError *))block
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppPubsub subscribeToNode:nodeName withOptions:nil];
}

-(void)addBuddy:(NSString *)jidStr withCallbackBlock:(void (^)(NSError *))block
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppRoster addUser:[XMPPJID jidWithString:jidStr] withNickname:nil];
}

-(void)removeBuddy:(NSString *)jidStr withCallbackBlock:(void (^)(NSError *))block
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppRoster removeUser:[XMPPJID jidWithString:jidStr]];
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
    
	[self goOnline];
    
    //fetch roster
#warning "Here needs some condition check, otherwise rosters are fetched everytime. ideally it only fetch first time
    [xmppRoster fetchRoster];
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
            Message *msg = [NetMessageConverter newMessageFromXMPPMessage:message inContext:_managedObjectContext];
            
            // MyNotificationName defined globally
            NSNotification *myNotification =
            [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:msg.conversation];
            [[NSNotificationQueue defaultQueue]
             enqueueNotification:myNotification
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationNoCoalescing
             forModes:nil];

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
#pragma mark XMPPRosterMemoryStoargeDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//
// everytime some poster change happened, local user db should be updated
//
- (void)xmppRoster:(XMPPRosterMemoryStorage *)sender didAddUser:(XMPPUserMemoryStorageObject *)user
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"add user: %@", user);
    
    NSString* ePostalID = [user.jid bare];
    
    XMPPUserMemoryStorageObject *me = [sender myUser];
    if ([ePostalID isEqualToString:[me.jid bare]]) {
        return;
    }
    
    User* thisUser = [ModelHelper findUserWithEPostalID:ePostalID inContext:_managedObjectContext];
    
    // insert user if it doesn't exist
    if (thisUser == nil || thisUser.state.intValue == IdentityStateInactive) {
        thisUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
    }
    
    if (thisUser.state.intValue != IdentityStateActive) {
        thisUser.name = user.nickname;
        thisUser.ePostalID = [user.jid bare];
        thisUser.displayName = [thisUser.ePostalID substringToIndex:[thisUser.ePostalID rangeOfString: @"@"].location];
        thisUser.type = [NSNumber numberWithInt:IdentityTypeUser];
        thisUser.state = [NSNumber numberWithInt:IdentityStateActive];
        MOCSave(_managedObjectContext);
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
    
    User* thisUser = [ModelHelper findUserWithEPostalID:ePostalID inContext:_managedObjectContext];
    
    // insert user if it doesn't exist
    if (thisUser == nil) {
        // weird - log an error
        DDLogError(@"user have to exist! ERROR NEED CHECK: %@", user);
    } else if (thisUser.state.intValue == IdentityStateActive || thisUser.state.intValue == IdentityStatePendingRemoveFriend) {
        thisUser.state = [NSNumber numberWithInt:IdentityStateInactive];
    }
}

//
// Implement this delegate so to create local users from the poster
// this function should only be used once
//
- (void)xmppRosterDidPopulate:(XMPPRosterMemoryStorage *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPUserMemoryStorageObject *me = [sender myUser];
    NSArray* roster = [sender unsortedUsers];
    NSInteger count = [roster count];
    for (int i = 0 ; i < count ; i++) {
        XMPPUserMemoryStorageObject *obj = [roster objectAtIndex:i];
        if ([obj.jid isEqualToJID:me.jid options:XMPPJIDCompareBare]) {
            continue;
        }
        
        NSString* ePostalID = [obj.jid bare];
        
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
        
        // insert user if it doesn't exist
        if ([array count] == 0) {
            User *userNS = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:_managedObjectContext];
            userNS.name = obj.nickname;
            userNS.ePostalID = [obj.jid bare];
            userNS.displayName = [userNS.ePostalID substringToIndex:[userNS.ePostalID rangeOfString: @"@"].location];
            userNS.type = [NSNumber numberWithInt:IdentityTypeUser];
            userNS.state = [NSNumber numberWithInt:IdentityStateActive];
        }
    }
    
    MOCSave(_managedObjectContext);
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
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        Message *msg = [NetMessageConverter newMessageFromXMPPPubsubMessage:message inContext:_managedObjectContext];
        
        if (msg == nil) {
            return;
        }
        
        if (msg) {
            // MyNotificationName defined globally
            NSNotification *myNotification =
            [NSNotification notificationWithName:NEW_MESSAGE_NOTIFICATION object:msg.conversation];
            [[NSNotificationQueue defaultQueue]
             enqueueNotification:myNotification
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationNoCoalescing
             forModes:nil];
        }
                
    }else{
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"Ok";
        localNotification.alertBody = [NSString stringWithFormat:@"From: "];
     
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
     }
    
    
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
    NSXMLElement *subscription = [pubsub elementForName:@"subscription"];
    NSString* subID = [subscription attributeStringValueForName:@"subid"];
    NSString *nodeStr = [subscription attributeStringValueForName:@"node"];
    
    //add the Channel to the addressbook
    Channel *channel = [ModelHelper findChannelWithNode:nodeStr inContext:_managedObjectContext];
    if (channel && channel.state.intValue == IdentityStatePendingAddSubscription) {
        channel.state = [NSNumber numberWithInt:IdentityStateActive];
        channel.subID = subID;
        MOCSave(_managedObjectContext);
    }
    
    NSString* csrftoken = [[NSUserDefaults standardUserDefaults] valueForKey:@"csrfmiddlewaretoken"];
    
    // notify server about the subscription 
    NSDictionary *postDict = [NSDictionary dictionaryWithObjectsAndKeys: channel.guid, @"guid", @"4", @"op", csrftoken, @"csrfmiddlewaretoken", nil];
        
    [[AppNetworkAPIClient sharedClient] postPath:POST_DATA_PATH parameters:postDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"login JSON received: %@", responseObject);
            
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"login failed: %@", error);
    }];

}


@end
