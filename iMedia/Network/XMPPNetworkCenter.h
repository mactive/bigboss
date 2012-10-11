//
//  XMPPNetworkCenter.h
//  iMedia
//
//  Created by Xiaosi Li on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

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

@end
