//
//  Me.m
//  iMedia
//
//  Created by Xiaosi Li on 11/8/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "Me.h"
#import "Avatar.h"
#import "Channel.h"


@implementation Me

@dynamic birthdate;
@dynamic career;
@dynamic cell;
@dynamic ePostalPassword;
@dynamic gender;
@dynamic hometown;
@dynamic privacyPass;
@dynamic alwaysbeen;
@dynamic interest;
@dynamic school;
@dynamic company;
@dynamic lastSearchPreference;
@dynamic name;
@dynamic password;
@dynamic selfIntroduction;
@dynamic signature;
@dynamic username;
@dynamic fullEPostalID;
@dynamic sinaWeiboID;
@dynamic config;
@dynamic avatars;
@dynamic channels;

-(NSArray *)getOrderedAvatars
{
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES];
    NSArray *result = [self.avatars sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    
    return result;
}


@end
