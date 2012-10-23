//
//  User.h
//  iMedia
//
//  Created by Xiaosi Li on 10/15/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Identity.h"

@class Conversation;

@interface User : Identity

@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * signature;
@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSSet *conversations;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(Conversation *)value;
- (void)removeConversationsObject:(Conversation *)value;
- (void)addConversations:(NSSet *)values;
- (void)removeConversations:(NSSet *)values;

@end
