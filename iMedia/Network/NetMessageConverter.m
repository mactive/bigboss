//
//  NetMessageConverter.m
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "NetMessageConverter.h"
#import "XMPPFramework.h"
#import "ModelHelper.h"
#import "Conversation.h"
#import "User.h"
#import "Channel.h"
#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"

@interface NetMessageConverter ()

@end


@implementation NetMessageConverter

+ (NSMutableDictionary *)threadToReceiverJidMap {
    static NSMutableDictionary  *_threadToReceiverJidMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _threadToReceiverJidMap = [[NSMutableDictionary alloc] initWithCapacity:5];
    });
    
    return _threadToReceiverJidMap;
}
+ (NSMutableDictionary *)threadToLastConversationDateMap {
    static NSMutableDictionary  *_threadToLastConversationdMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _threadToLastConversationdMap = [[NSMutableDictionary alloc] initWithCapacity:5];
    });
    
    return _threadToLastConversationdMap;
}

//
// msg comes from two sources: 1. User; 2. A CS rep of a business (i.e., invisible user). All 1-1 no pubsub
//
// This function converts between XMPPMessage and our message

+(Message *)newMessageFromXMPPMessage:(XMPPMessage *)msg inContext:(NSManagedObjectContext *)context
{
    NSString* jid = [[msg from] bare];
    Message *message;
    User *from = [[ModelHelper sharedInstance] findUserWithEPostalID:jid];
    NSString *node ; 
    BOOL isCloseMsg ; 
    NSString* rateKey = nil;
    
    
    if (from == nil) {
        node = [[msg elementForName:@"thread"] stringValue];
        isCloseMsg = [@"" isEqualToString:[[msg elementForName:@"close"] stringValue]];
        rateKey = [[msg elementForName:@"rate"] stringValue];
        
        if (isCloseMsg) {
            [[self threadToReceiverJidMap] removeObjectForKey:node];
            return nil;
        }
        
        if (!StringHasValue(node)) {
            // not from a known user nor from a cs rep
            return nil;
        }
    }
  
    message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];
    message.sentDate = [NSDate date];
    if (StringHasValue(rateKey)) {
        // is a final rate message
        message.text = rateKey;
        message.type = [NSNumber numberWithInt:MessageTypeRate];
    } else {
        message.text = [[msg elementForName:@"body"] stringValue];
        message.type = [NSNumber numberWithInt:MessageTypeChat];
    }
    
    Conversation *conv;
    if (from != nil) {
        message.from = from;
        NSSet *results = [from.conversations objectsPassingTest:^(id obj, BOOL *stop){
            Conversation *conv = (Conversation *)obj;
            if ([conv.users count] == 1) {
                return YES;
            }
            return NO;
        }];
            
        if ([results count] == 0)
        {
            conv = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:context];
            [conv addUsersObject:from];
        } else {
            conv = [results anyObject];
        }

    } else {
        Channel *channel = [[ModelHelper sharedInstance] findChannelWithNode:node];
        message.from = channel;
        conv = channel.conversation;
        
        if (StringHasValue(rateKey)) {
            [[self threadToReceiverJidMap] removeObjectForKey:node];
            [[self threadToLastConversationDateMap] removeObjectForKey:node];
        } else {
            [[self threadToReceiverJidMap] setValue:[[msg from] full] forKey:node];
            [[self threadToLastConversationDateMap] setValue:[NSDate date] forKey:node];
        }
    }
            
        
    // Find a conversation that this message belongs. That is judged by the conversation's user list.
    conv.lastMessageSentDate = message.sentDate;
    conv.lastMessageText = message.text;
    [conv addMessagesObject:message];
    
    return message;
}

#define NS_PUBSUB_EVENT    @"http://jabber.org/protocol/pubsub#event"

+(Message *)newMessageFromXMPPPubsubMessage:(XMPPMessage *)message inContext:(NSManagedObjectContext *)context
{
    NSXMLElement *event = [message elementForName:@"event" xmlns:NS_PUBSUB_EVENT];
    NSXMLElement *items = [event elementForName:@"items"];
    NSXMLElement *item = [items elementForName:@"item"];
    NSXMLElement *entry = [item elementForName:@"entry"];
    NSXMLElement *link = [entry elementForName:@"link"];
    NSString* linkValue = [link attributeStringValueForName:@"href"];
    NSString* summary = [[entry elementForName:@"text"] stringValue];
    NSString *nodeStr = [items attributeStringValueForName:@"node"];
    NSString *itemID = [item attributeStringValueForName:@"id"];
    
    if (item == nil) {
        return nil;
    }

    Channel *channel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
    
    if (channel == nil) {
        //Channel hasn't been setup
        return nil;
    }
    if (channel.conversation == nil){
        channel.conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:context];
    }
    NSSet *messages = channel.conversation.messages;
    BOOL isDuplicate = NO;
    NSEnumerator *enumerator = [messages objectEnumerator];
    id obj;
    while (obj = [enumerator nextObject]) {
        Message *m = obj;
        if (m.transportID != nil && [m.transportID isEqualToString:itemID]) {
            isDuplicate = YES;
            return nil;
        }
    }
    
    Message *msg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];

#warning Hasn't handle the rich text storage yet
    msg.from = channel;
    msg.sentDate = [NSDate date];
 //   msg.text = [@"http://" stringByAppendingString:linkValue];
    msg.text = [entry XMLString];
    msg.type = [NSNumber numberWithInt:MessageTypePublish];
    msg.transportID = itemID;
    
    channel.conversation.lastMessageSentDate = msg.sentDate;
    channel.conversation.lastMessageText = summary;
    [channel.conversation addMessagesObject:msg];
    
    return msg;
}



////////////////////////////////////////////////////////////////////////////////////////
#pragma mark conversion for the other way
////////////////////////////////////////////////////////////////////////////////////////

+(XMPPMessage *)newXMPPMessageFromMessage:(Message *)message
{
    NSString* toJid = @"";
    const int kOneHourInSeconds = - 3600;
    //
    // Here we simulate a cs session with the assumption that if we have received a chat for this node from a cs person,
    // we store the cs jid which can be used in subsequence chat. and we will remove this jid reference once the cs
    // tell us the conversation is over by receving the rating request
    //
    // however, in case the rating request is LOST, we need a way to recover. The best simulation so far is to use a
    // session auto expire with time. Say, if within an hour there has been no exchange between user and cs, we stop this session
    // and start a new session
    if (message.conversation.channel != nil) {
        NSString* csJID = [[self threadToReceiverJidMap] valueForKey:message.conversation.channel.node];
        NSDate *last_talk_date = [[self threadToLastConversationDateMap] valueForKey:message.conversation.channel.node];
        NSTimeInterval diff = [last_talk_date timeIntervalSinceNow];
        if (StringHasValue(csJID) && (abs(diff) > kOneHourInSeconds)) {
            toJid = csJID;
        } else {
            toJid = message.conversation.channel.csContactPostalID;
        }
    } else {
        User *to = [message.conversation.users anyObject]; // here we suppose a conversation only between two parties
        toJid = to.ePostalID;
    }
    
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:toJid]];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:message.text];
    [msg  addChild:body];
    
    if (message.conversation.channel != nil) {
        NSXMLElement *thread = [NSXMLElement elementWithName:@"thread" stringValue:message.conversation.channel.node];
        [msg addChild:thread];
    }
    
    return msg;
}

@end
