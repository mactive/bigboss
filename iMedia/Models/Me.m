//
//  Me.m
//  iMedia
//
//  Created by Xiaosi Li on 10/26/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "Me.h"
#import "Avatar.h"


@implementation Me

@dynamic ePostalPassword;
@dynamic password;
@dynamic username;
@dynamic avatars;

-(NSArray *)getOrderedAvatars
{
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES];
    NSArray *result = [self.avatars sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    
    return result;
}

@end
