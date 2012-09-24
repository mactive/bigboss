//
//  Message.h
//  iMedia
//
//  Created by Xiaosi Li on 9/20/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPMessage;

@interface Message : NSObject

@property (nonatomic, strong) XMPPMessage* message;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* body;

@end
