//
//  NetMessageConverter.m
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "NetMessageConverter.h"
#import "XMPPFramework.h"
#import "ModelSearchHelper.h"
#import "Conversation.h"
#import "User.h"

@implementation NetMessageConverter

//
// msg comes from three sources: 1. User; 2. A business; 3. A CS rep of a business (i.e., invisible user)
//
// This function converts between XMPPMessage and our message

+(Message *)newMessageFromXMPPMessage:(XMPPMessage *)msg inContext:(NSManagedObjectContext *)context
{
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];
        
    NSString* jid = [[msg from] bare];
        
    User *from = [ModelSearchHelper findUserWithEPostalID:jid inContext:context];
        
    if (from == nil)
    {
        // it could be from a channel or from a CS repre
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

+(XMPPMessage *)newXMPPMessageFromMessage:(Message *)message
{
    User *to = [message.conversation.users anyObject]; // here we suppose a conversation only between two parties
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:to.ePostalID]];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:message.text];
    [msg  addChild:body];
    
    return msg;
}

@end
