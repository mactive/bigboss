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

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface XMPPNetworkCenter () <XMPPRosterDelegate, XMPPPubSubDelegate>
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
    
    // Setup XMPP PubSub
    //xmppPubsub = [[XMPPPubSub alloc] initWithServiceJID:[XMPPJID jidWithString:@"pubsub.192.168.1.104"]];
    //[xmppPubsub subscribeToNode:@"summer" withOptions:nil];
    
    
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

-(BOOL)sendMessage:(NSDictionary *)msgDict
{
    NSString* msgBody = [msgDict valueForKey:MESSAGE_BODY_DICT_KEY];
    
    XMPPMessage *msg = [XMPPMessage messageWithType:[msgDict valueForKey:MESSAGE_TYPE_DICT_KEY] to:[XMPPJID jidWithString:[msgDict valueForKey:MESSAGE_TO_DICT_KEY]]];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:msgBody];
    [msg  addChild:body];
    [self.xmppStream sendElement:msg];
    
  //  NSNumber *messageSendingIndex = @([_messagesSending count]);
    //[_messagesSending setObject:message forKey:messageSendingIndex];
    return YES;
}


@end
