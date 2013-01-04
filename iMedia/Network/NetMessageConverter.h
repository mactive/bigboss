//
//  NetMessageConverter.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "Channel.h"
#import "User.h"

@class XMPPMessage;
@class XMPPIQ;

@interface NetMessageConverter : NSObject

+(Message *)newMessageFromXMPPMessage:(XMPPMessage *)msg inContext:(NSManagedObjectContext *)context;
+(Message *)newMessageFromXMPPPubsubMessage:(XMPPMessage *)msg inContext:(NSManagedObjectContext *)context;

+(Message *)createFriendRequestApprovedMessageFromUser:(User*)user inContext:(NSManagedObjectContext *)context;

+(XMPPMessage *)newXMPPMessageFromMessage:(Message *)msg;
@end
