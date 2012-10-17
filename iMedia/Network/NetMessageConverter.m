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

@implementation NetMessageConverter

//
// msg comes from two sources: 1. User; 2. A CS rep of a business (i.e., invisible user). All 1-1 no pubsub
//
// This function converts between XMPPMessage and our message

+(Message *)newMessageFromXMPPMessage:(XMPPMessage *)msg inContext:(NSManagedObjectContext *)context
{
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];
        
    NSString* jid = [[msg from] bare];
        
    User *from = [ModelHelper findUserWithEPostalID:jid inContext:context];
        
    if (from == nil)
    {
        // it is from a CS repre
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
        conv = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:context];
        [conv addUsersObject:from];
    } else {
        conv = [results anyObject];
    }
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
    
    if (item == nil) {
        return nil;
    }

    Channel *channel = [ModelHelper findChannelWithNode:nodeStr inContext:context];
    
    if (channel == nil) {
        //Channel hasn't been setup
        return nil;
    }
    
    Message *msg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];

#warning Hasn't handle the rich text storage yet
    msg.from = channel;
    msg.sentDate = [NSDate date];
    msg.text = [@"http://" stringByAppendingString:linkValue];
    msg.type = [NSNumber numberWithInt:MessageTypePublish];
    
    if (channel.conversation == nil)
    {
        channel.conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:context];
    }
    
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
    if (message.conversation.channel != nil) {
        toJid = message.conversation.channel.csContactPostalID;
    } else {
        User *to = [message.conversation.users anyObject]; // here we suppose a conversation only between two parties
        toJid = to.ePostalID;
    }
    
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:toJid]];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:message.text];
    [msg  addChild:body];
    
    return msg;
}

@end
