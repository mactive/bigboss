//
//  XMPPNetworkCenter.h
//  iMedia
//
//  Created by Xiaosi Li on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//
//  This class is to wrap all the XMPP communications/classes inside. Outside of this file there would be no XMPP
//  entities
//
//  To achieve the above pupose, this class knows about our data model. It will create and delete NSManagedObjects
//  (i.e. update our local data storage) and send notifications so that interesting party can perform actions
//

#define NS_PUBSUB          @"http://jabber.org/protocol/pubsub"

#define NEW_MESSAGE_NOTIFICATION @"NewMessage"
#define NEW_FRIEND_NOTIFICATION   @"FriendRequest"

@class Message;

@interface XMPPNetworkCenter : NSObject

+ (XMPPNetworkCenter *)sharedClient;

@property (strong, nonatomic) NSManagedObjectContext* managedObjectContext;

-(BOOL)connectWithUsername:(NSString *)username andPassword:(NSString *)password;
-(BOOL)setupWithHostname:(NSString *)hostname andPort:(int)port;
-(void)teardownStream;

-(BOOL)disconnect;
-(BOOL)isConnected;

-(BOOL)sendMessage:(Message *)message;
-(NSString *)subscribeToChannel:(NSString *)nodeName withCallbackBlock:(void (^)(NSError *error))block;
-(NSString *)unsubscribeToChannel:(NSString *)nodeName withCallbackBlock:(void (^)(NSError *error))block;

-(void)addBuddy:(NSString *)jidStr withCallbackBlock:(void (^)(NSError *error))block;
-(void)removeBuddy:(NSString *)jidStr withCallbackBlock:(void (^)(NSError *erro))block;

- (void)acceptPresenceSubscriptionRequestFrom:(NSString *)jidStr andAddToRoster:(BOOL)flag;
- (void)rejectPresenceSubscriptionRequestFrom:(NSString *)jidStr;


@end
