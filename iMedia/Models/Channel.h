//
//  Channel.h
//  iMedia
//
//  Created by Li Xiaosi on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Channel : NSManagedObject

@property (nonatomic, retain) NSString * announcePostalID;
@property (nonatomic, retain) NSString * receiverPostalID;
@property (nonatomic, retain) NSString * csPostalIDPattern;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) Conversation *conversation;

@end
