//
//  Conversation.h
//  iMedia
//
//  Created by Li Xiaosi on 10/10/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, Message, User;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * draft;
@property (nonatomic, retain) NSDate * lastMessageSentDate;
@property (nonatomic, retain) NSString * lastMessageText;
@property (nonatomic, retain) NSNumber * messagesLength;
@property (nonatomic, retain) NSNumber * unreadMessagesCount;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *users;
@property (nonatomic, retain) Channel *channel;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
