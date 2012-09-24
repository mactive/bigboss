//
//  Message.m
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "Message.h"
#import "XMPPFramework.h"

@implementation Message

@synthesize message;

- (NSString *)from
{
    return message.fromStr;
}

- (NSString *)body
{
    if ([message isMessageWithBody]) {
        NSString *body = [[message elementForName:@"body"] stringValue];
        return body;
    }
    
    return nil;
}

@end
