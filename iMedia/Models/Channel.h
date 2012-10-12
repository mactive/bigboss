//
//  Channel.h
//  iMedia
//
//  Created by Xiaosi Li on 10/12/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Identity.h"

@class Conversation;

@interface Channel : Identity

@property (nonatomic, retain) NSString * node;
@property (nonatomic, retain) NSString * csContactPostalID;
@property (nonatomic, retain) Conversation *conversation;

@end
