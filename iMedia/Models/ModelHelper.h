//
//  ModelSearchHelper.h
//  iMedia
//
//  Created by Xiaosi Li on 10/11/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBJson.h"

@class User;
@class Channel;
@class Identity;

@interface ModelHelper : NSObject

+ (User *)findUserWithEPostalID:(NSString *)ePostalID inContext:(NSManagedObjectContext*)context;
+ (Channel *)findChannelWithNode:(NSString *)node inContext:(NSManagedObjectContext *)context;
+ (Channel *)findChannelWithSubrequestID:(NSString *)subID inContext:(NSManagedObjectContext *)context;

+ (void)populateIdentity:(Identity *)identity withJSONData:(NSString *)json;


+ (User *)newUserInContext:(NSManagedObjectContext *)context;

+ (SBJsonParser *)sharedJSONParser;

@end
