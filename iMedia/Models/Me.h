//
//  Me.h
//  iMedia
//
//  Created by Xiaosi Li on 11/8/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Identity.h"

@class Avatar, Channel;

@interface Me : Identity

@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSString * career;
@property (nonatomic, retain) NSString * cell;
@property (nonatomic, retain) NSString * ePostalPassword;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * hometown;
@property (nonatomic, retain) NSDate * lastSyncFromServerDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * selfIntroduction;
@property (nonatomic, retain) NSString * signature;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * fullEPostalID;
@property (nonatomic, retain) NSSet *avatars;
@property (nonatomic, retain) NSSet *channels;
@property (nonatomic, retain) NSNumber *config;

-(NSArray *)getOrderedAvatars;

@end

@interface Me (CoreDataGeneratedAccessors)

- (void)addAvatarsObject:(Avatar *)value;
- (void)removeAvatarsObject:(Avatar *)value;
- (void)addAvatars:(NSSet *)values;
- (void)removeAvatars:(NSSet *)values;

- (void)addChannelsObject:(Channel *)value;
- (void)removeChannelsObject:(Channel *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

@end
