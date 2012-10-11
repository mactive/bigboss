//
//  NetMessageConverter.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "XMPPMessage.h"

@interface NetMessageConverter : NSObject

+(Message *)newMessageFromXMPPMessage:(XMPPMessage *)msg inContext:(NSManagedObjectContext *)context;
+(XMPPMessage *)newXMPPMessageFromMessage:(Message *)msg;

@end
