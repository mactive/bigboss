//
//  ModelSearchHelper.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class Channel;
@class Identity;
@class Pluggin;
@class FriendRequest;

@interface ModelHelper : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (ModelHelper *)sharedInstance;

- (User *)findUserWithEPostalID:(NSString *)ePostalID;
- (User *)findUserWithGUID:(NSString *)guid;
- (Channel *)findChannelWithNode:(NSString *)node;
- (Channel *)findChannelWithSubrequestID:(NSString *)subID;
- (Pluggin *)findFriendRequestPluggin;

- (void)populateIdentity:(Identity *)identity withJSONData:(id)json;


- (User *)createNewUser;
- (FriendRequest *)newFriendRequestWithEPostalID:(NSString *)jid andJson:(id)jsonData;

- (User *)createActiveUserWithFullServerJSONData:(id)jsonData;

- (void)clearAllObjects;

@end
