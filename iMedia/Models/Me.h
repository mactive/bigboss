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

#define THUMBNAIL_IMAGE_CHANGE_NOTIFICATION @"THUMBNAIL_IMAGE_CHANGE_NOTIFICATION"  

@class Avatar, Channel;

@interface Me : Identity

@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSString * career;
@property (nonatomic, retain) NSString * cell;
@property (nonatomic, retain) NSString * ePostalPassword;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * hometown;
@property (nonatomic, retain) NSString * privacyPass;
@property (nonatomic, retain) NSString * alwaysbeen;
@property (nonatomic, retain) NSString * interest;
@property (nonatomic, retain) NSString * school;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSString * lastSearchPreference;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * selfIntroduction;
@property (nonatomic, retain) NSString * signature;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * fullEPostalID;
@property (nonatomic, retain) NSString * sinaWeiboID;
@property (nonatomic, retain) NSSet *avatars;
@property (nonatomic, retain) NSSet *channels;
@property (nonatomic) u_int64_t config;

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
