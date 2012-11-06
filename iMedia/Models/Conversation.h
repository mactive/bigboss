//
//  Conversation.h
//  iMedia
//
//  Created by Xiaosi Li on 10/12/12.
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
@property (nonatomic) int16_t unreadMessagesCount;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *users;
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
