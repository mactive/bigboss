//
//  User.h
//  iMedia
//
//  Created by Xiaosi Li on 11/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Identity.h"

@class Conversation;

@interface User : Identity

@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSString * career;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * hometown;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * selfIntroduction;
@property (nonatomic, retain) NSString * signature;
@property (nonatomic, retain) NSSet *inConversations;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addInConversationsObject:(Conversation *)value;
- (void)removeInConversationsObject:(Conversation *)value;
- (void)addInConversations:(NSSet *)values;
- (void)removeInConversations:(NSSet *)values;

@end
