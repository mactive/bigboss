//
//  Conversation.h
//  iMedia
//
//  Created by Xiaosi Li on 11/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Identity, Message, User;

typedef enum _ConversationType
{
    ConversationTypeSingleUserChat = 1,
    ConversationTypeGroupChat      = 2,
    ConversationTypeMediaChannel        = 3,
    ConversationTypePlugginFriendRequest = 10
} ConversationType;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * draft;
@property (nonatomic, retain) NSDate * lastMessageSentDate;
@property (nonatomic, retain) NSString * lastMessageText;
@property (nonatomic)           u_int32_t messagesLength;
@property (nonatomic)           u_int16_t unreadMessagesCount;
@property (nonatomic)         u_int16_t type;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) Identity *ownerEntity;
@property (nonatomic, retain) NSSet *attendees;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addAttendeesObject:(User *)value;
- (void)removeAttendeesObject:(User *)value;
- (void)addAttendees:(NSSet *)values;
- (void)removeAttendees:(NSSet *)values;

@end
