//
//  Message.h
//  iMedia
//
//  Created by Xiaosi Li on 9/27/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation, User;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, retain) User *from;

@end
