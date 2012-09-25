//
//  Conversation.h
//  iMedia
//
//  Created by Xiaosi Li on 9/25/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * draft;
@property (nonatomic, retain) NSDate * lastMessageSentDate;
@property (nonatomic, retain) NSString * lastMessageText;
@property (nonatomic, retain) NSNumber * messagesLength;
@property (nonatomic, retain) NSNumber * unreadMessagesCount;
@property (nonatomic, retain) NSSet *users;
@property (nonatomic, retain) NSSet *messages;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addUsersObject:(NSManagedObject *)value;
- (void)removeUsersObject:(NSManagedObject *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

- (void)addMessagesObject:(NSManagedObject *)value;
- (void)removeMessagesObject:(NSManagedObject *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
