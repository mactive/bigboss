//
//  Message.h
//  iMedia
//
//  Created by Xiaosi Li on 11/8/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation, Identity;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * bodyType;
@property (nonatomic, retain) NSString * transportID;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, retain) Identity *from;

@end
