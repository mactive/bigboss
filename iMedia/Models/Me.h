//
//  Me.h
//  iMedia
//
//  Created by Xiaosi Li on 10/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User.h"


@interface Me : User

@property (nonatomic, retain) NSString * ePostalPassword;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *avatars;

- (NSArray *)getOrderedAvatars;
@end

@interface Me (CoreDataGeneratedAccessors)

- (void)addAvatarsObject:(NSManagedObject *)value;
- (void)removeAvatarsObject:(NSManagedObject *)value;
- (void)addAvatars:(NSSet *)values;
- (void)removeAvatars:(NSSet *)values;

@end
