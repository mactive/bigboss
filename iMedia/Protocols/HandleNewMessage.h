//
//  HandleNewMessage.h
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Message;

@protocol HandleNewMessageDelegate <NSObject>

- (void)receiveNewMessage:(Message *)message;
- (void)receiveNewEvent:(NSString *)content;

@end
