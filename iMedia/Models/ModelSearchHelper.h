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

@interface ModelSearchHelper : NSObject

+ (User *)findUserWithEPostalID:(NSString *)ePostalID inContext:(NSManagedObjectContext*)context;
+ (Channel *)findChannelWithNode:(NSString *)node inContext:(NSManagedObjectContext *)context;

@end
