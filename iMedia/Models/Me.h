//
//  Me.h
//  iMedia
//
//  Created by Xiaosi Li on 10/28/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Identity.h"

@class Avatar;

@interface Me : Identity

@property (nonatomic, retain) NSString * ePostalPassword;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * signature;
@property (nonatomic, retain) NSDate   * birthdate;
@property (nonatomic, retain) NSString * cell;
@property (nonatomic, retain) NSString * hometown;
@property (nonatomic, retain) NSString * selfIntroduction;
@property (nonatomic, retain) NSString * career;
@property (nonatomic, retain) NSSet *avatars;

-(NSArray *)getOrderedAvatars;

@end

@interface Me (CoreDataGeneratedAccessors)

- (void)addAvatarsObject:(Avatar *)value;
- (void)removeAvatarsObject:(Avatar *)value;
- (void)addAvatars:(NSSet *)values;
- (void)removeAvatars:(NSSet *)values;

@end
